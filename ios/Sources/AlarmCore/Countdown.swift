import Foundation

/// A deadline-based countdown does not accumulate timer callback drift or lose time during suspension.
public struct Countdown: Codable, Equatable, Sendable {
    public enum State: String, Codable, Sendable { case ready, running, paused, done }
    public static let allowedDuration = 1...86_399
    public private(set) var duration: Int
    public private(set) var deadline: Date?
    public private(set) var pausedRemaining: TimeInterval?
    public private(set) var state: State = .ready

    public init(duration: Int = 300) {
        self.duration = min(Self.allowedDuration.upperBound, max(1, duration))
    }

    public func remaining(at date: Date) -> Int {
        if let deadline { return max(0, Int(ceil(deadline.timeIntervalSince(date)))) }
        if state == .done { return 0 }
        return Int(ceil(pausedRemaining ?? Double(duration)))
    }

    public mutating func start(at date: Date) {
        guard state != .running else { return }
        deadline = date.addingTimeInterval(pausedRemaining ?? Double(duration))
        pausedRemaining = nil
        state = .running
    }

    public mutating func pause(at date: Date) {
        guard state == .running, let deadline else { return }
        if deadline <= date {
            finish(at: date)
            return
        }
        pausedRemaining = deadline.timeIntervalSince(date)
        self.deadline = nil
        state = .paused
    }

    public mutating func finish(at date: Date) {
        guard state == .running, let deadline, deadline <= date else { return }
        complete()
    }

    /// System timing is authoritative after a pause/resume from the lock screen or after relaunch.
    public mutating func applySystemCountdown(deadline: Date) {
        self.deadline = deadline
        pausedRemaining = nil
        state = .running
    }

    public mutating func applySystemPause(remaining: TimeInterval) {
        deadline = nil
        pausedRemaining = max(0, remaining)
        state = .paused
    }

    public mutating func complete() {
        deadline = nil
        pausedRemaining = nil
        state = .done
    }

    public mutating func reset(duration: Int? = nil) {
        if let duration { self.duration = min(Self.allowedDuration.upperBound, max(1, duration)) }
        deadline = nil
        pausedRemaining = nil
        state = .ready
    }
}
