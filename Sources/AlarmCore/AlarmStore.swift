import Foundation
import Observation

public struct SystemAlarm: Equatable, Sendable {
    public var id: UUID
    public var isAlerting: Bool
    public init(id: UUID, isAlerting: Bool = false) {
        self.id = id
        self.isAlerting = isAlerting
    }
}

@MainActor public protocol AlarmScheduling {
    func authorize() async throws
    func alarms() throws -> [SystemAlarm]
    func schedule(_ alarm: AlarmRecord) async throws
    func cancel(id: UUID) throws
    func stop(id: UUID) throws
}

@MainActor @Observable public final class AlarmStore {
    public private(set) var records: [AlarmRecord] = []
    public private(set) var systemAlarms: [SystemAlarm] = []
    public private(set) var isBusy = false
    public private(set) var needsRecovery = false
    public private(set) var storageFailed = false
    public var errorMessage: String?
    @ObservationIgnored private let scheduler: any AlarmScheduling
    @ObservationIgnored private let repository: any AlarmPersistence
    @ObservationIgnored private var document = AlarmDocument()

    public init(scheduler: any AlarmScheduling, repository: any AlarmPersistence) {
        self.scheduler = scheduler
        self.repository = repository
        do {
            document = try repository.load()
            records = document.records
            needsRecovery = document.change != nil
        } catch {
            storageFailed = true
            errorMessage = error.localizedDescription
        }
    }

    public var primaryAlarms: [AlarmRecord] {
        records.filter { $0.parentID == nil }.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }
    public var ringing: [AlarmRecord] {
        let ids = Set(systemAlarms.filter(\.isAlerting).map(\.id))
        // Include journal additions so a disk failure cannot hide a ringing alarm.
        return (records + (document.change?.additions ?? [])).filter { ids.contains($0.systemID) }
    }
    public func isScheduled(_ record: AlarmRecord) -> Bool {
        systemAlarms.contains { $0.id == record.systemID }
    }
    public func nextAlarm(after date: Date, calendar: Calendar = .current) -> (AlarmRecord, Date)? {
        records.filter { isScheduled($0) }.compactMap { record in
            record.nextFire(after: date, calendar: calendar).map { (record, $0) }
        }.min { $0.1 < $1.1 }
    }

    public func save(_ input: AlarmRecord, now: Date = Date(), calendar: Calendar = .current) async -> Bool {
        await mutate {
            var alarm = input
            try alarm.validate()
            alarm.label = alarm.label.trimmingCharacters(in: .whitespacesAndNewlines)
            if alarm.label.isEmpty { alarm.label = "Alarm" }
            // New registrations let a failed schedule leave the previous alarm intact.
            alarm.systemID = UUID()
            alarm.fireDate = nil
            if alarm.weekdays.isEmpty, alarm.isEnabled {
                alarm.fireDate = alarm.nextFire(after: now, calendar: calendar)
            }
            let removed = document.records.filter { $0.id == alarm.id || $0.parentID == alarm.id }
            let target = document.records.filter { $0.id != alarm.id && $0.parentID != alarm.id } + [alarm]
            try await commit(
                target: target, additions: alarm.isEnabled ? [alarm] : [],
                cancellations: Set(removed.map(\.systemID)))
        }
    }

    public func delete(_ alarm: AlarmRecord) async -> Bool {
        await mutate {
            let removed = document.records.filter { $0.id == alarm.id || $0.parentID == alarm.id }
            try await commit(
                target: document.records.filter { $0.id != alarm.id && $0.parentID != alarm.id },
                additions: [], cancellations: Set(removed.map(\.systemID)))
        }
    }

    public func snooze(_ alarm: AlarmRecord, now: Date = Date(), calendar: Calendar = .current) async -> Bool {
        await mutate {
            guard systemAlarms.contains(where: { $0.id == alarm.systemID && $0.isAlerting }) else { return }
            let date = now.addingTimeInterval(Double(alarm.snoozeMinutes * 60))
            var child = alarm
            child.id = UUID()
            child.systemID = UUID()
            child.parentID = alarm.parentID ?? alarm.id
            child.weekdays = []
            child.fireDate = date
            child.hour = calendar.component(.hour, from: date)
            child.minute = calendar.component(.minute, from: date)
            child.isEnabled = true
            // Schedule and persist the snooze before stopping the sounding alarm.
            let olderChildren = document.records.filter { $0.parentID == child.parentID && $0.id != alarm.id }
            let target = document.records.filter { !olderChildren.contains($0) } + [child]
            try await commit(target: target, additions: [child], cancellations: Set(olderChildren.map(\.systemID)))
            try scheduler.stop(id: alarm.systemID)
            try reconcile()
        }
    }

    public func stop(_ alarm: AlarmRecord) async -> Bool {
        await mutate {
            try scheduler.stop(id: alarm.systemID)
            try reconcile()
        }
    }

    /// Refresh is read-only with respect to scheduling: missing alarms never silently re-arm.
    public func refresh() {
        guard !isBusy, !storageFailed else { return }
        do { try reconcile() } catch { errorMessage = error.localizedDescription }
    }

    public func retry() async {
        guard !isBusy, !storageFailed else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            try await finishChange()
            try reconcile()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    /// Reverse the journal through the same durable path, including partially cancelled old alarms.
    public func discardChange() async {
        guard !isBusy, !storageFailed, let change = document.change else { return }
        // A previous discard may itself have failed; resume its journal instead of reversing it again.
        if change.target == document.records {
            await retry()
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            var rollback = document
            rollback.change = AlarmChange(
                target: document.records,
                additions: document.records.filter { $0.isEnabled && change.cancellations.contains($0.systemID) },
                cancellations: Set(change.additions.map(\.systemID)).subtracting(document.records.map(\.systemID))
            )
            try repository.save(rollback)
            document = rollback
            try await finishChange()
            try reconcile()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func mutate(_ action: () async throws -> Void) async -> Bool {
        guard !isBusy else { return false }
        guard !storageFailed else {
            errorMessage = AlarmFailure.corruptStorage.localizedDescription
            return false
        }
        guard document.change == nil else {
            errorMessage = AlarmFailure.unfinishedChange.localizedDescription
            return false
        }
        isBusy = true
        defer { isBusy = false }
        do {
            try await action()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            systemAlarms = (try? scheduler.alarms()) ?? systemAlarms
            return false
        }
    }

    private func commit(target: [AlarmRecord], additions: [AlarmRecord], cancellations: Set<UUID>) async throws {
        if !additions.isEmpty { try await scheduler.authorize() }
        var staged = document
        staged.change = AlarmChange(target: target, additions: additions, cancellations: cancellations)
        // The journal is durable before any system mutation, including cancellation.
        try repository.save(staged)
        document = staged
        needsRecovery = true
        try await finishChange()
        try reconcile()
    }

    private func finishChange() async throws {
        guard let change = document.change else { return }
        var ids = Set(try scheduler.alarms().map(\.id))
        if !change.additions.isEmpty { try await scheduler.authorize() }
        for alarm in change.additions where !ids.contains(alarm.systemID) {
            // Do not replay an expired one-time alarm during crash recovery.
            if let fireDate = alarm.fireDate, fireDate <= Date() { continue }
            try await scheduler.schedule(alarm)
            ids.insert(alarm.systemID)
        }
        for id in change.cancellations where ids.contains(id) {
            try scheduler.cancel(id: id)
        }
        let completed = AlarmDocument(records: change.target)
        try repository.save(completed)
        document = completed
        records = completed.records
        needsRecovery = false
    }

    private func reconcile() throws {
        systemAlarms = try scheduler.alarms()
        guard document.change == nil else { return }
        let ids = Set(systemAlarms.map(\.id))
        var updated = document
        updated.records = updated.records.compactMap { record in
            guard record.isEnabled, !ids.contains(record.systemID) else { return record }
            if record.parentID != nil { return nil }
            var disabled = record
            disabled.isEnabled = false
            return disabled
        }
        if updated != document {
            try repository.save(updated)
            document = updated
            records = updated.records
        }
    }
}
