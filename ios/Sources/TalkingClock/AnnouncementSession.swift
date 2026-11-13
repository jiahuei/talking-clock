import AlarmCore
import Foundation
import Observation

/// Foreground scheduling only until the physical-device background programme gate is passed.
@MainActor @Observable final class AnnouncementSession {
    var clockMinutes = 0
    var timerInterval = 60
    private(set) var nextClock: Date?
    var errorMessage: String?
    private let audio: AlarmAudio
    private var clockTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?

    init(audio: AlarmAudio) { self.audio = audio }

    func updateClock(active: Bool) {
        clockTask?.cancel()
        nextClock = nil
        guard active, clockMinutes > 0 else { return }
        clockTask = Task {
            while !Task.isCancelled {
                guard let next = IntervalScheduler.nextClock(after: Date(), minutes: clockMinutes) else { return }
                nextClock = next
                do {
                    try await Task.sleep(for: .seconds(max(0, next.timeIntervalSinceNow)))
                    try Task.checkCancellation()
                    // Waking late after suspension never replays an obsolete announcement.
                    if Date().timeIntervalSince(next) < 2 { try await audio.speakNow() }
                } catch is CancellationError { return } catch {
                    errorMessage = error.localizedDescription
                    return
                }
            }
        }
    }

    func updateTimer(deadline: Date?, active: Bool) {
        timerTask?.cancel()
        guard active, let deadline else { return }
        timerTask = Task {
            while !Task.isCancelled {
                guard let next = IntervalScheduler.nextTimer(after: Date(), deadline: deadline, interval: timerInterval)
                else { return }
                do {
                    try await Task.sleep(for: .seconds(max(0, next.timeIntervalSinceNow)))
                    try Task.checkCancellation()
                    if Date().timeIntervalSince(next) < 2 {
                        try await audio.speak(SpokenTime.remaining(Int(deadline.timeIntervalSince(next).rounded())))
                    }
                } catch is CancellationError { return } catch {
                    errorMessage = error.localizedDescription
                    return
                }
            }
        }
    }
}
