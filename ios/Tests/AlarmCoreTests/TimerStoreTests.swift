import Foundation
import XCTest

@testable import AlarmCore

@MainActor private final class FakeTimerScheduler: TimerScheduling {
    var registration: TimerRegistration?
    var fails = false
    var prepared = false
    func prepare() async throws {
        if fails { throw AlarmFailure.permissionDenied }
        prepared = true
    }
    func schedule(id: UUID, duration: Int) async throws {
        if fails { throw AlarmFailure.unfinishedChange }
        registration = .countdown
    }
    func state(id: UUID) throws -> TimerRegistration? { registration }
    func pause(id: UUID) throws {
        if fails { throw AlarmFailure.unfinishedChange }
        registration = .paused
    }
    func resume(id: UUID) throws {
        if fails { throw AlarmFailure.unfinishedChange }
        registration = .countdown
    }
    func cancel(id: UUID) throws {
        if fails { throw AlarmFailure.unfinishedChange }
        registration = nil
    }
}

@MainActor final class TimerStoreTests: XCTestCase {
    private var scheduler: FakeTimerScheduler!
    private var defaults: UserDefaults!
    private var suite: String!
    private var store: TimerStore!
    private var date = Date(timeIntervalSince1970: 1_900_000_000)

    override func setUp() async throws {
        suite = "TalkingClockTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        scheduler = FakeTimerScheduler()
        store = TimerStore(scheduler: scheduler, defaults: defaults, now: { self.date })
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suite)
        store = nil
    }

    /// Ensures denied authorization cannot turn a ready timer into a running countdown.
    func testStartFailure() async {
        scheduler.fails = true
        await store.start()
        XCTAssertEqual(store.countdown.state, .ready)
        XCTAssertNil(scheduler.registration)
        XCTAssertNotNil(store.errorMessage)
    }

    /// Ensures pause and resume update the countdown only after their system operation succeeds.
    func testPauseResumeFailures() async {
        await store.start()
        XCTAssertTrue(scheduler.prepared)
        date = date.addingTimeInterval(30)
        scheduler.fails = true
        store.pause()
        XCTAssertEqual(store.countdown.state, .running)
        scheduler.fails = false
        store.pause()
        XCTAssertEqual(store.countdown.state, .paused)
        XCTAssertEqual(store.countdown.remaining(at: date), 270)
        scheduler.fails = true
        await store.start()
        XCTAssertEqual(store.countdown.state, .paused)
        scheduler.fails = false
        date = date.addingTimeInterval(60)
        await store.start()
        XCTAssertEqual(store.countdown.deadline, date.addingTimeInterval(270))
    }

    /// Ensures a failed cancellation preserves the old timer instead of offering a conflicting new duration.
    func testResetFailure() async {
        await store.start()
        scheduler.fails = true
        store.reset(duration: 60)
        XCTAssertEqual(store.countdown.duration, 300)
        XCTAssertEqual(store.countdown.state, .running)
        scheduler.fails = false
        store.reset(duration: 60)
        XCTAssertEqual(store.countdown.duration, 60)
        XCTAssertEqual(store.countdown.state, .ready)
        XCTAssertNil(scheduler.registration)
    }

    /// Ensures reopening restores a live deadline and a missing system timer is never automatically re-armed.
    func testReloadAndExternalCancellation() async {
        await store.start()
        let restored = TimerStore(scheduler: scheduler, defaults: defaults, now: { self.date })
        restored.refresh()
        XCTAssertEqual(restored.countdown, store.countdown)
        scheduler.registration = nil
        restored.refresh()
        XCTAssertEqual(restored.countdown.state, .ready)
        XCTAssertNil(scheduler.registration)
    }

    /// Ensures system completion leads to Done and Restart replaces the completed registration.
    func testCompletionAndRestart() async {
        await store.start()
        scheduler.registration = .alerting
        store.refresh()
        XCTAssertEqual(store.countdown.state, .done)
        await store.start()
        XCTAssertEqual(store.countdown.state, .running)
        XCTAssertEqual(store.countdown.remaining(at: date), 300)
    }

    /// Ensures choosing a preset while paused cancels the old system timer before changing its duration.
    func testPresetWhilePaused() async {
        await store.start()
        store.pause()
        store.setDuration(150)
        XCTAssertEqual(store.countdown.state, .ready)
        XCTAssertEqual(store.countdown.duration, 150)
        XCTAssertNil(scheduler.registration)
    }
}
