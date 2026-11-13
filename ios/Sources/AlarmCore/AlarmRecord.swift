import Foundation

public enum AlarmFailure: LocalizedError {
    case invalidTime, invalidLabel, invalidWeekdays, invalidSnooze, corruptStorage, busy, permissionDenied,
        unfinishedChange

    public var errorDescription: String? {
        switch self {
        case .invalidTime: return "Choose a valid hour and minute."
        case .invalidLabel: return "Use an alarm label of 60 characters or fewer."
        case .invalidWeekdays: return "Choose valid repeat days."
        case .invalidSnooze: return "Choose a snooze of 1 to 30 minutes."
        case .corruptStorage: return "Saved alarms could not be read. Your file has been preserved."
        case .busy: return "Another alarm change is still being saved."
        case .permissionDenied: return "Allow alarms in Settings to enable Talking Clock alarms."
        case .unfinishedChange: return "A previous change is unfinished. Use Retry sync before making another change."
        }
    }
}

public struct AlarmRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var systemID: UUID
    public var label: String
    public var hour: Int
    public var minute: Int
    /// Calendar weekday values: Sunday = 1, Saturday = 7.
    public var weekdays: Set<Int>
    public var announcesTime: Bool
    public var snoozeMinutes: Int
    public var isEnabled: Bool
    /// One-time alarms use a fixed date so reopening cannot move a missed alarm to tomorrow.
    public var fireDate: Date?
    public var parentID: UUID?

    public init(
        id: UUID = UUID(), systemID: UUID = UUID(), label: String = "Wake up", hour: Int = 7,
        minute: Int = 0, weekdays: Set<Int> = [], announcesTime: Bool = true,
        snoozeMinutes: Int = 9, isEnabled: Bool = true, fireDate: Date? = nil, parentID: UUID? = nil
    ) {
        self.id = id
        self.systemID = systemID
        self.label = label
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.announcesTime = announcesTime
        self.snoozeMinutes = snoozeMinutes
        self.isEnabled = isEnabled
        self.fireDate = fireDate
        self.parentID = parentID
    }

    public func validate() throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else { throw AlarmFailure.invalidTime }
        guard label.count <= 60 else { throw AlarmFailure.invalidLabel }
        guard weekdays.isSubset(of: Set(1...7)) else { throw AlarmFailure.invalidWeekdays }
        guard (1...30).contains(snoozeMinutes) else { throw AlarmFailure.invalidSnooze }
        guard parentID != id else { throw AlarmFailure.corruptStorage }
    }

    public func nextFire(after date: Date, calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        if let fireDate { return fireDate > date ? fireDate : nil }
        let days: [Int?] = weekdays.isEmpty ? [nil] : weekdays.sorted().map(Optional.some)
        return days.compactMap { day in
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.second = 0
            components.weekday = day
            return calendar.nextDate(
                after: date, matching: components, matchingPolicy: .nextTime,
                repeatedTimePolicy: .first, direction: .forward)
        }.min()
    }

    public func displayDate(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: hour, minute: minute)) ?? .distantPast
    }

    public func repeatDescription(locale: Locale = .current) -> String {
        if parentID != nil { return "Snoozed" }
        if weekdays.isEmpty { return "Once" }
        if weekdays.count == 7 { return "Every day" }
        if weekdays == Set(2...6) { return "Weekdays" }
        if weekdays == [1, 7] { return "Weekends" }
        let formatter = DateFormatter()
        formatter.locale = locale
        return weekdays.sorted().map { formatter.shortWeekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }
}
