import Foundation
import XCTest
@testable import AlarmCore

final class AlarmCalendarTests: XCTestCase {
    private func calendar(_ zone: String = "UTC") -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zone)!
        return result
    }
    private func date(_ string: String) -> Date { ISO8601DateFormatter().date(from: string)! }

    /// Ensures selecting an already elapsed time schedules tomorrow, not immediately.
    func testOneTimeRollsPastMidnight() {
        let alarm = AlarmRecord(hour: 0, minute: 5)
        XCTAssertEqual(alarm.nextFire(after: date("2030-01-01T23:59:00Z"), calendar: calendar()), date("2030-01-02T00:05:00Z"))
    }

    /// Ensures an exact time boundary is exclusive and cannot trigger twice.
    func testExactMinuteMovesForward() {
        let alarm = AlarmRecord(hour: 7)
        XCTAssertEqual(alarm.nextFire(after: date("2030-01-01T07:00:00Z"), calendar: calendar()), date("2030-01-02T07:00:00Z"))
    }

    /// Ensures Friday evening's weekday alarm advances to Monday.
    func testWeekdayRollover() {
        let alarm = AlarmRecord(hour: 7, weekdays: Set(2...6))
        XCTAssertEqual(alarm.nextFire(after: date("2030-01-04T20:00:00Z"), calendar: calendar()), date("2030-01-07T07:00:00Z"))
    }

    /// Ensures the spring DST gap advances to the next valid wall-clock time.
    func testSpringForward() {
        let alarm = AlarmRecord(hour: 2, minute: 30)
        XCTAssertEqual(alarm.nextFire(after: date("2030-03-10T08:00:00Z"), calendar: calendar("America/Los_Angeles")),
                       date("2030-03-10T10:00:00Z"))
    }

    /// Ensures the fall DST overlap chooses the first occurrence.
    func testFallBack() {
        let alarm = AlarmRecord(hour: 1, minute: 30)
        XCTAssertEqual(alarm.nextFire(after: date("2030-11-03T07:00:00Z"), calendar: calendar("America/Los_Angeles")),
                       date("2030-11-03T08:30:00Z"))
    }

    /// Ensures weekly wall-clock alarms follow the supplied local time zone.
    func testTimeZoneChanges() {
        let alarm = AlarmRecord(hour: 7, weekdays: Set(1...7))
        let now = date("2030-01-01T00:00:00Z")
        XCTAssertEqual(alarm.nextFire(after: now, calendar: calendar("Asia/Taipei")), date("2030-01-01T23:00:00Z"))
        XCTAssertEqual(alarm.nextFire(after: now, calendar: calendar()), date("2030-01-01T07:00:00Z"))
    }

    /// Ensures an expired fixed alarm is never rolled to tomorrow and disabled alarms have no next date.
    func testFixedAndDisabledAlarms() {
        let now = date("2030-01-01T00:00:00Z")
        XCTAssertNil(AlarmRecord(fireDate: now).nextFire(after: now))
        XCTAssertNil(AlarmRecord(isEnabled: false).nextFire(after: now))
    }

    /// Guards persisted and edited records against invalid times, days, labels, and snooze values.
    func testValidation() {
        for alarm in [AlarmRecord(hour: 24), AlarmRecord(minute: -1), AlarmRecord(weekdays: [0]),
                      AlarmRecord(snoozeMinutes: 0), AlarmRecord(label: String(repeating: "x", count: 61))] {
            XCTAssertThrowsError(try alarm.validate())
        }
        XCTAssertNoThrow(try AlarmRecord(hour: 23, minute: 59, weekdays: Set(1...7), snoozeMinutes: 30).validate())
    }
}

@MainActor private final class MemoryRepository: AlarmPersistence {
    var document = AlarmDocument()
    var writes = 0
    var failAtWrite: Int?
    var failLoad = false
    func load() throws -> AlarmDocument {
        if failLoad { throw AlarmFailure.corruptStorage }
        return document
    }
    func save(_ document: AlarmDocument) throws {
        writes += 1
        if failAtWrite == writes { throw TestFailure.expected }
        self.document = document
    }
}

private enum TestFailure: Error { case expected }

@MainActor private final class FakeScheduler: AlarmScheduling {
    var registered: [UUID: AlarmRecord] = [:]
    var alerting = Set<UUID>()
    var denied = false
    var failSchedule = false
    var failCancel = false
    var failRead = false
    var scheduleCalls = 0
    var onSchedule: (() -> Void)?
    var hold: CheckedContinuation<Void, Never>?
    var shouldHold = false
    func authorize() async throws { if denied { throw AlarmFailure.permissionDenied } }
    func alarms() throws -> [SystemAlarm] {
        if failRead { throw TestFailure.expected }
        return registered.keys.map { SystemAlarm(id: $0, isAlerting: alerting.contains($0)) }
    }
    func schedule(_ alarm: AlarmRecord) async throws {
        scheduleCalls += 1
        onSchedule?()
        if shouldHold { await withCheckedContinuation { hold = $0 } }
        if failSchedule { throw TestFailure.expected }
        registered[alarm.systemID] = alarm
    }
    func cancel(id: UUID) throws {
        if failCancel { throw TestFailure.expected }
        registered[id] = nil
        alerting.remove(id)
    }
    func stop(id: UUID) throws {
        alerting.remove(id)
        if registered[id]?.weekdays.isEmpty == true { registered[id] = nil }
    }
}

@MainActor final class AlarmStoreTests: XCTestCase {
    private var repository: MemoryRepository!
    private var scheduler: FakeScheduler!
    private var store: AlarmStore!
    override func setUp() async throws {
        repository = MemoryRepository()
        scheduler = FakeScheduler()
        store = AlarmStore(scheduler: scheduler, repository: repository)
    }
    private func savedRepeating() async -> AlarmRecord {
        let saved = await store.save(AlarmRecord(weekdays: Set(2...6)))
        XCTAssertTrue(saved)
        return store.records[0]
    }

    /// Ensures successful saves have durable records and a real registration.
    func testSaveAndReload() async {
        let alarm = await savedRepeating()
        XCTAssertTrue(store.isScheduled(alarm))
        let reloaded = AlarmStore(scheduler: scheduler, repository: repository)
        reloaded.refresh()
        XCTAssertEqual(reloaded.records, [alarm])
        XCTAssertNil(repository.document.change)
    }

    /// Ensures denial never persists an enabled alarm or touches system schedules.
    func testDeniedPermission() async {
        scheduler.denied = true
        let saved = await store.save(AlarmRecord())
        XCTAssertFalse(saved)
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(repository.writes, 0)
        XCTAssertEqual(scheduler.scheduleCalls, 0)
    }

    /// Ensures a failed journal write cannot create an untracked system alarm.
    func testStorageFailureBeforeScheduling() async {
        repository.failAtWrite = 1
        let saved = await store.save(AlarmRecord())
        XCTAssertFalse(saved)
        XCTAssertEqual(scheduler.scheduleCalls, 0)
        XCTAssertFalse(store.needsRecovery)
    }

    /// Ensures scheduling failure retains the old alarm and retry completes the replacement.
    func testFailedEditPreservesOldAlarm() async {
        let old = await savedRepeating()
        var edited = old
        edited.hour = 8
        scheduler.failSchedule = true
        let saved = await store.save(edited)
        XCTAssertFalse(saved)
        XCTAssertNotNil(scheduler.registered[old.systemID])
        XCTAssertEqual(store.records, [old])
        XCTAssertTrue(store.needsRecovery)
        scheduler.failSchedule = false
        await store.retry()
        XCTAssertEqual(store.records.first?.hour, 8)
        XCTAssertNil(scheduler.registered[old.systemID])
        XCTAssertFalse(store.needsRecovery)
    }

    /// Ensures a crash after scheduling but before final disk commit is recoverable without duplicates.
    func testFinalWriteFailureRecoversOnRelaunch() async {
        repository.failAtWrite = 2
        let saved = await store.save(AlarmRecord(weekdays: [2]))
        XCTAssertFalse(saved)
        XCTAssertEqual(scheduler.registered.count, 1)
        let relaunched = AlarmStore(scheduler: scheduler, repository: repository)
        await relaunched.retry()
        XCTAssertEqual(scheduler.scheduleCalls, 1)
        XCTAssertEqual(relaunched.records.count, 1)
        XCTAssertFalse(relaunched.needsRecovery)
    }

    /// Ensures cancellation failure remains journaled and retry removes the obsolete schedule.
    func testCancelFailureRecovery() async {
        let old = await savedRepeating()
        scheduler.failCancel = true
        let deleted = await store.delete(old)
        XCTAssertFalse(deleted)
        XCTAssertTrue(store.needsRecovery)
        scheduler.failCancel = false
        await store.retry()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertTrue(scheduler.registered.isEmpty)
    }

    /// Ensures a missing one-time alarm is disabled instead of being re-created on launch.
    func testDismissedOneTimeStaysOff() async {
        let saved = await store.save(AlarmRecord())
        XCTAssertTrue(saved)
        scheduler.registered.removeAll()
        store.refresh()
        XCTAssertFalse(store.records[0].isEnabled)
        XCTAssertEqual(scheduler.scheduleCalls, 1)
    }

    /// Ensures unavailable system state does not disable persisted alarms based on an empty guess.
    func testFailedSystemReadPreservesRecords() async {
        let old = await savedRepeating()
        scheduler.failRead = true
        store.refresh()
        XCTAssertEqual(store.records, [old])
        XCTAssertNotNil(store.errorMessage)
    }

    /// Ensures snooze has its own identity and does not overwrite a repeating parent's schedule.
    func testSnoozePreservesRepeatAndParentDeleteCancelsChild() async {
        let parent = await savedRepeating()
        scheduler.alerting.insert(parent.systemID)
        store.refresh()
        let now = Date()
        let snoozed = await store.snooze(parent, now: now)
        XCTAssertTrue(snoozed)
        XCTAssertEqual(scheduler.registered.count, 2)
        let child = store.records.first { $0.parentID == parent.id }!
        XCTAssertEqual(child.fireDate, now.addingTimeInterval(9 * 60))
        XCTAssertNotEqual(child.systemID, parent.systemID)
        XCTAssertEqual(store.records.first { $0.id == parent.id }?.weekdays, Set(2...6))
        let deleted = await store.delete(parent)
        XCTAssertTrue(deleted)
        XCTAssertTrue(scheduler.registered.isEmpty)
    }

    /// Ensures a completed snooze is removed and never re-arms itself.
    func testStopSnoozeRemovesChild() async {
        let parent = await savedRepeating()
        scheduler.alerting.insert(parent.systemID)
        store.refresh()
        _ = await store.snooze(parent)
        let child = store.records.first { $0.parentID != nil }!
        scheduler.alerting.insert(child.systemID)
        store.refresh()
        _ = await store.stop(child)
        XCTAssertEqual(store.records, [parent])
        XCTAssertEqual(scheduler.registered.count, 1)
    }

    /// Ensures corrupt storage is preserved rather than overwritten with empty defaults.
    func testCorruptStorageBlocksMutation() async {
        repository.failLoad = true
        let broken = AlarmStore(scheduler: scheduler, repository: repository)
        let saved = await broken.save(AlarmRecord())
        XCTAssertFalse(saved)
        XCTAssertTrue(broken.storageFailed)
        XCTAssertEqual(repository.writes, 0)
    }

    /// Ensures concurrent saves cannot interleave across the asynchronous scheduler boundary.
    func testConcurrentMutationIsRejected() async {
        scheduler.shouldHold = true
        let entered = expectation(description: "scheduling started")
        scheduler.onSchedule = { entered.fulfill() }
        let first = Task { await store.save(AlarmRecord(weekdays: [2])) }
        await fulfillment(of: [entered], timeout: 2)
        let second = await store.save(AlarmRecord(hour: 8))
        XCTAssertFalse(second)
        scheduler.hold?.resume()
        let firstResult = await first.value
        XCTAssertTrue(firstResult)
        XCTAssertEqual(store.records.count, 1)
    }

    /// Ensures a failed edit cannot be silently overwritten by another mutation.
    func testPendingChangeBlocksNewMutation() async {
        scheduler.failSchedule = true
        _ = await store.save(AlarmRecord(weekdays: [2]))
        let second = await store.save(AlarmRecord(hour: 8))
        XCTAssertFalse(second)
        XCTAssertEqual(scheduler.scheduleCalls, 1)
    }

    /// Ensures old fixed-date journal entries cannot replay expired alarms on retry.
    func testExpiredRecoveryDoesNotReschedule() async {
        let alarm = AlarmRecord(fireDate: Date(timeIntervalSince1970: 1))
        repository.document = AlarmDocument(change: AlarmChange(target: [alarm], additions: [alarm], cancellations: []))
        let recovered = AlarmStore(scheduler: scheduler, repository: repository)
        await recovered.retry()
        XCTAssertEqual(scheduler.scheduleCalls, 0)
        XCTAssertFalse(recovered.records[0].isEnabled)
    }
}

@MainActor final class AlarmRepositoryTests: XCTestCase {
    /// Ensures atomic disk persistence round-trips records and preserves an unreadable file.
    func testDiskRoundTripAndCorruption() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("alarms.json")
        let repository = FileAlarmRepository(url: url)
        XCTAssertEqual(try repository.load().records, [])
        let document = AlarmDocument(records: [AlarmRecord(weekdays: [2, 4, 6])])
        try repository.save(document)
        XCTAssertEqual(try repository.load(), document)
        let corrupt = Data("not json".utf8)
        try corrupt.write(to: url)
        XCTAssertThrowsError(try repository.load())
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    /// Ensures unsupported schemas and duplicate identities cannot enter the store.
    func testSchemaValidation() throws {
        let alarm = AlarmRecord()
        XCTAssertThrowsError(try AlarmDocument(records: [alarm, alarm]).validate())
        var future = AlarmDocument()
        future.version = 2
        XCTAssertThrowsError(try future.validate())
    }
}
