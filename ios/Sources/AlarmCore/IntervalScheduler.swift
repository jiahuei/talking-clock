import Foundation

public enum IntervalScheduler {
    public static let clockMinutes = [5, 15, 30, 60]
    public static let timerSeconds = [30, 60, 300]
    public static let alarmSeconds = [15, 30, 60]

    /// Calendar matching keeps boundaries aligned to local time, including DST transitions.
    public static func nextClock(after date: Date, minutes: Int, calendar: Calendar = .current) -> Date? {
        guard clockMinutes.contains(minutes) else { return nil }
        return stride(from: 0, to: 60, by: minutes).compactMap { minute in
            calendar.nextDate(
                after: date, matching: DateComponents(minute: minute, second: 0),
                matchingPolicy: .nextTime, repeatedTimePolicy: .first)
        }.min()
    }

    /// Strictly excludes the starting value and zero, which belongs to the system completion alert.
    public static func nextTimer(after date: Date, deadline: Date, interval: Int) -> Date? {
        guard timerSeconds.contains(interval) else { return nil }
        let remaining = deadline.timeIntervalSince(date)
        let multiple = (ceil(remaining / Double(interval)) - 1) * Double(interval)
        guard multiple > 0 else { return nil }
        return deadline.addingTimeInterval(-multiple)
    }
}
