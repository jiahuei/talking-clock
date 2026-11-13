import Foundation
import XCTest

@testable import AlarmCore

final class SpokenToolsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Ensures display and speech share the requested English minute and day-period rules.
    func testClockPhrases() {
        for (hour, minute, expected) in [
            (4, 0, "It's four o'clock at night."),
            (4, 45, "It's quarter to five in the morning."),
            (7, 15, "It's quarter past seven in the morning."),
            (12, 30, "It's half past twelve in the afternoon."),
            (16, 43, "It's four forty-three in the afternoon."),
            (16, 45, "It's quarter to five in the evening."),
            (20, 45, "It's quarter to nine at night."),
            (23, 45, "It's quarter to twelve at night."),
            (0, 5, "It's twelve oh five at night."),
        ] {
            XCTAssertEqual(SpokenTime.clock(hour: hour, minute: minute), expected)
        }
        XCTAssertEqual(
            SpokenTime.clock(hour: 16, minute: 43, includesIntroduction: false),
            "Four forty-three in the afternoon.")
        XCTAssertEqual(
            SpokenTime.alarm(AlarmRecord(label: "Practice", hour: 7, minute: 15)),
            "It's quarter past seven in the morning. Practice.")
    }

    /// Ensures timer phrases omit zero units and distinguish completion from remaining time.
    func testTimerPhrases() {
        XCTAssertEqual(SpokenTime.remaining(5405), "One hour thirty minutes five seconds left.")
        XCTAssertEqual(SpokenTime.remaining(150), "Two minutes thirty seconds left.")
        XCTAssertEqual(SpokenTime.remaining(1), "One second left.")
        XCTAssertEqual(SpokenTime.remaining(0), "Time's up.")
        XCTAssertEqual(SpokenTime.duration(3600), "one hour")
    }

    /// Ensures clock boundaries align to wall time and never repeat the current boundary.
    func testClockBoundaries() {
        let date = calendar.date(from: DateComponents(year: 2030, month: 1, day: 1, hour: 23, minute: 45))!
        for interval in IntervalScheduler.clockMinutes {
            let next = IntervalScheduler.nextClock(after: date, minutes: interval, calendar: calendar)!
            XCTAssertGreaterThan(next, date)
            XCTAssertEqual(calendar.component(.minute, from: next) % interval, 0)
            XCTAssertEqual(calendar.component(.second, from: next), 0)
        }
        XCTAssertNil(IntervalScheduler.nextClock(after: date, minutes: 0))
        XCTAssertEqual(
            IntervalScheduler.nextClock(after: date, minutes: 15, calendar: calendar),
            date.addingTimeInterval(900))
    }

    /// Ensures DST gaps and repeated hours still produce a future aligned local boundary.
    func testClockDSTBoundaries() {
        var calendar = calendar
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        for timestamp in ["2030-03-10T09:59:59Z", "2030-11-03T08:59:59Z"] {
            let date = ISO8601DateFormatter().date(from: timestamp)!
            let next = IntervalScheduler.nextClock(after: date, minutes: 15, calendar: calendar)!
            XCTAssertGreaterThan(next, date)
            XCTAssertLessThanOrEqual(next.timeIntervalSince(date), 901)
            XCTAssertEqual(calendar.component(.minute, from: next) % 15, 0)
        }
    }

    /// Ensures remaining-time multiples exclude the initial duration and the final system alert.
    func testTimerBoundaries() {
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        XCTAssertEqual(
            IntervalScheduler.nextTimer(after: now, deadline: now.addingTimeInterval(300), interval: 60),
            now.addingTimeInterval(60))
        XCTAssertEqual(
            IntervalScheduler.nextTimer(after: now, deadline: now.addingTimeInterval(150), interval: 60),
            now.addingTimeInterval(30))
        XCTAssertNil(IntervalScheduler.nextTimer(after: now, deadline: now.addingTimeInterval(30), interval: 60))
    }

    /// Ensures pause/resume preserves fractional time and elapsed wall time survives a suspended UI.
    func testCountdownLifecycle() {
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        var timer = Countdown(duration: 150)
        timer.start(at: now)
        timer.pause(at: now.addingTimeInterval(30.5))
        XCTAssertEqual(timer.state, .paused)
        XCTAssertEqual(timer.remaining(at: now.addingTimeInterval(1000)), 120)
        timer.start(at: now.addingTimeInterval(1000))
        XCTAssertEqual(timer.deadline, now.addingTimeInterval(1119.5))
        timer.finish(at: now.addingTimeInterval(2000))
        XCTAssertEqual(timer.state, .done)
        XCTAssertEqual(timer.remaining(at: now), 0)
        timer.start(at: now)
        XCTAssertEqual(timer.remaining(at: now), 150)
        timer.reset(duration: 86_399)
        XCTAssertEqual(timer.state, .ready)
        XCTAssertEqual(timer.remaining(at: now), 86_399)
    }

    /// Ensures invalid new snooze settings fail without changing the default or accepted endpoints.
    func testSnoozeRange() {
        XCTAssertEqual(AlarmRecord().snoozeMinutes, 9)
        for minutes in [1, 16, 30] { XCTAssertThrowsError(try AlarmRecord(snoozeMinutes: minutes).validate()) }
        for minutes in [2, 15] { XCTAssertNoThrow(try AlarmRecord(snoozeMinutes: minutes).validate()) }
    }

    /// Ensures legacy snooze values are migrated durably in committed and pending journal snapshots.
    @MainActor func testLegacySnoozeMigration() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("alarms.json")
        let records = [AlarmRecord(snoozeMinutes: 1), AlarmRecord(snoozeMinutes: 30)]
        var legacy = AlarmDocument(
            records: records,
            change: AlarmChange(target: records, additions: records, cancellations: Set(records.map(\.systemID))))
        legacy.version = 1
        try JSONEncoder().encode(legacy).write(to: url)
        let migrated = try FileAlarmRepository(url: url).load()
        XCTAssertEqual(migrated.version, 2)
        XCTAssertEqual(migrated.records.map(\.snoozeMinutes), [2, 15])
        XCTAssertEqual(migrated.change?.target.map(\.snoozeMinutes), [2, 15])
        XCTAssertEqual(migrated.change?.additions.map(\.snoozeMinutes), [2, 15])
        XCTAssertEqual(migrated.records.map(\.systemID), records.map(\.systemID))
        XCTAssertEqual(try JSONDecoder().decode(AlarmDocument.self, from: Data(contentsOf: url)), migrated)
    }

    /// Ensures migration preserves corrupt files rather than hiding invalid old data with clamping.
    @MainActor func testCorruptLegacySnoozeIsPreserved() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        var legacy = AlarmDocument(records: [AlarmRecord(snoozeMinutes: 0)])
        legacy.version = 1
        let bytes = try JSONEncoder().encode(legacy)
        try bytes.write(to: url)
        XCTAssertThrowsError(try FileAlarmRepository(url: url).load())
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }
}
