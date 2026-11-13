import Foundation
import Observation

public enum TimerRegistration: Sendable { case countdown, paused, alerting }

@MainActor public protocol TimerScheduling {
    func prepare() async throws
    func schedule(id: UUID, duration: Int) async throws
    func state(id: UUID) throws -> TimerRegistration?
    func pause(id: UUID) throws
    func resume(id: UUID) throws
    func cancel(id: UUID) throws
}

@MainActor @Observable public final class TimerStore {
    public private(set) var countdown = Countdown()
    public private(set) var isBusy = false
    public var errorMessage: String?
    private let scheduler: any TimerScheduling
    private let now: () -> Date
    private let defaults: UserDefaults
    // A stable, dedicated ID lets Reset recover the system timer even if local UI state is unreadable.
    private let systemID = UUID(uuidString: "3A62574D-C928-47EA-A203-8EC952CD536D")!
    private let storageKey = "countdown-v1"

    public init(
        scheduler: any TimerScheduling, defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init
    ) {
        self.scheduler = scheduler
        self.now = now
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey) {
            do { countdown = try JSONDecoder().decode(Countdown.self, from: data) } catch {
                errorMessage = "The saved timer could not be read. Use Reset to cancel any existing timer."
            }
        }
    }

    public func setDuration(_ seconds: Int) {
        guard !isBusy, countdown.state != .running else { return }
        // A paused countdown still owns a system registration, so selection must cancel it first.
        reset(duration: seconds)
    }

    public func start() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            if countdown.state == .paused {
                try scheduler.resume(id: systemID)
                countdown.start(at: now())
            } else {
                if countdown.state == .done, try scheduler.state(id: systemID) != nil {
                    try scheduler.cancel(id: systemID)
                }
                guard try scheduler.state(id: systemID) == nil else {
                    errorMessage = "A timer is already registered. Use Reset before starting another."
                    return
                }
                try await scheduler.prepare()
                var staged = countdown
                staged.start(at: now())
                // Store the deadline before scheduling; launch reconciliation never re-arms a missing timer.
                defaults.set(try JSONEncoder().encode(staged), forKey: storageKey)
                try await scheduler.schedule(id: systemID, duration: countdown.duration)
                countdown = staged
            }
            persist()
            errorMessage = nil
        } catch {
            persist()
            errorMessage = error.localizedDescription
        }
    }

    public func pause() {
        guard !isBusy, countdown.state == .running else { return }
        do {
            try scheduler.pause(id: systemID)
            countdown.pause(at: now())
            persist()
        } catch { errorMessage = error.localizedDescription }
    }

    public func reset(duration: Int? = nil) {
        guard !isBusy else { return }
        do {
            if try scheduler.state(id: systemID) != nil {
                try scheduler.cancel(id: systemID)
            }
            countdown.reset(duration: duration)
            persist()
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    public func refresh() {
        guard !isBusy else { return }
        do {
            let previous = countdown
            let alarm = try scheduler.state(id: systemID)
            if alarm == nil {
                if countdown.state == .running {
                    countdown.finish(at: now())
                    if countdown.state == .running { countdown.reset() }
                } else if countdown.state == .paused {
                    countdown.reset()
                }
            } else if alarm == .alerting {
                countdown.finish(at: .distantFuture)
            }
            if countdown != previous { persist() }
        } catch { errorMessage = error.localizedDescription }
    }

    private func persist() {
        do { defaults.set(try JSONEncoder().encode(countdown), forKey: storageKey) } catch {
            errorMessage = error.localizedDescription
        }
    }
}
