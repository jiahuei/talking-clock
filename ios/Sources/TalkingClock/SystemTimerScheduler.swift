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
        switch alarm.state {
        case .countdown: return .countdown
        case .paused: return .paused
        case .alerting: return .alerting
        default: return .countdown
        }
    }

    func pause(id: UUID) throws { try AlarmManager.shared.pause(id: id) }
    func resume(id: UUID) throws { try AlarmManager.shared.resume(id: id) }
    func cancel(id: UUID) throws { try AlarmManager.shared.cancel(id: id) }
}
