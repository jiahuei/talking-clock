import ActivityKit
import AlarmKit
import AlarmCore
import AppIntents
import SwiftUI

struct ClockAlarmMetadata: AlarmMetadata {}

struct OpenClockIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Talking Clock"
    static var openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}

@MainActor final class SystemAlarmScheduler: AlarmScheduling {
    private let manager = AlarmManager.shared
    private let audio: AlarmAudio
    init(audio: AlarmAudio) { self.audio = audio }

    func authorize() async throws {
        let state = try await manager.requestAuthorization()
        guard state == .authorized else { throw AlarmFailure.permissionDenied }
    }

    func alarms() throws -> [SystemAlarm] {
        try manager.alarms.map { SystemAlarm(id: $0.id, isAlerting: $0.state == .alerting) }
    }

    func schedule(_ alarm: AlarmRecord) async throws {
        let sound: AlertConfiguration.AlertSound
        if alarm.announcesTime { sound = .named(try await audio.sound(for: alarm)) }
        else { sound = .default }

        let schedule: Alarm.Schedule
        if let date = alarm.fireDate { schedule = .fixed(date) }
        else {
            let weekdays: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
            schedule = .relative(.init(time: .init(hour: alarm.hour, minute: alarm.minute),
                                       repeats: .weekly(alarm.weekdays.sorted().map { weekdays[$0 - 1] })))
        }
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: alarm.label),
            stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill"),
            secondaryButton: AlarmButton(text: "Open", textColor: .white, systemImageName: "arrow.up.right"),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alert),
                                         metadata: ClockAlarmMetadata(), tintColor: Color.orange)
        let configuration = AlarmManager.AlarmConfiguration<ClockAlarmMetadata>.alarm(
            schedule: schedule, attributes: attributes, secondaryIntent: OpenClockIntent(), sound: sound
        )
        _ = try await manager.schedule(id: alarm.systemID, configuration: configuration)
    }

    func cancel(id: UUID) throws { try manager.cancel(id: id) }
    func stop(id: UUID) throws { try manager.stop(id: id) }
}
