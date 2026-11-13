import ActivityKit
import AlarmCore
import AlarmKit
import SwiftUI

@MainActor final class SystemTimerScheduler: TimerScheduling {
    private let audio: AlarmAudio
    private var soundName: String?
    init(audio: AlarmAudio) { self.audio = audio }

    func prepare() async throws {
        guard try await AlarmManager.shared.requestAuthorization() == .authorized else {
            throw AlarmFailure.permissionDenied
        }
        soundName = try await audio.sound(text: "Time's up.")
    }

    func schedule(id: UUID, duration: Int) async throws {
        guard let soundName else { throw AlarmFailure.unfinishedChange }
        let presentation = AlarmPresentation(
            alert: AlarmPresentation.Alert(
                title: "Time's up",
                stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill")),
            countdown: AlarmPresentation.Countdown(title: "Timer"),
            paused: AlarmPresentation.Paused(
                title: "Paused",
                resumeButton: AlarmButton(text: "Resume", textColor: .white, systemImageName: "play.fill")))
        let attributes = AlarmAttributes(presentation: presentation, metadata: TimerMetadata(), tintColor: .orange)
        let configuration = AlarmManager.AlarmConfiguration<TimerMetadata>.timer(
            duration: TimeInterval(duration), attributes: attributes, sound: .named(soundName))
        _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }

    func state(id: UUID) throws -> TimerRegistration? {
        guard let alarm = try AlarmManager.shared.alarms.first(where: { $0.id == id }) else { return nil }
        // The alarm registration says whether it exists; its Live Activity carries current timing.
        // A cached local deadline cannot account for a lock-screen Resume action.
        let mode = Activity<AlarmAttributes<TimerMetadata>>.activities.first {
            $0.content.state.alarmID == id
        }?.content.state.mode
        switch alarm.state {
        case .countdown:
            if case .countdown(let value) = mode { return .countdown(deadline: value.fireDate) }
            return .countdown(deadline: nil)
        case .paused:
            if case .paused(let value) = mode {
                return .paused(remaining: value.totalCountdownDuration - value.previouslyElapsedDuration)
            }
            return .paused(remaining: nil)
        case .alerting: return .alerting
        default: return .countdown(deadline: nil)
        }
    }

    func pause(id: UUID) throws { try AlarmManager.shared.pause(id: id) }
    func resume(id: UUID) throws { try AlarmManager.shared.resume(id: id) }
    func cancel(id: UUID) throws { try AlarmManager.shared.cancel(id: id) }
}
