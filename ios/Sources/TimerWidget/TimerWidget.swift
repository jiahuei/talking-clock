import ActivityKit
import AlarmCore
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

struct StopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop timer"
    @Parameter(title: "Alarm ID") var alarmID: String
    init() {}
    init(alarmID: String) { self.alarmID = alarmID }
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) { try AlarmManager.shared.cancel(id: id) }
        return .result()
    }
}

struct TimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<TimerMetadata>.self) { context in
            HStack {
                Label("Timer", systemImage: "timer")
                Spacer()
                TimerStateView(state: context.state)
                Button(intent: StopTimerIntent(alarmID: context.state.alarmID.uuidString)) {
                    Image(systemName: "stop.fill")
                }.accessibilityLabel("Stop timer")
            }.padding().activityBackgroundTint(.black).activitySystemActionForegroundColor(.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Label("Timer", systemImage: "timer") }
                DynamicIslandExpandedRegion(.trailing) { TimerStateView(state: context.state) }
                DynamicIslandExpandedRegion(.bottom) {
                    Button("Stop timer", intent: StopTimerIntent(alarmID: context.state.alarmID.uuidString))
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                TimerStateView(state: context.state).frame(maxWidth: 70)
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

private struct TimerStateView: View {
    let state: AlarmPresentationState
    var body: some View {
        switch state.mode {
        case .countdown(let countdown):
            Text(timerInterval: countdown.startDate...countdown.fireDate, countsDown: true).monospacedDigit()
        case .paused(let paused):
            Text(
                Duration.seconds(max(0, paused.totalCountdownDuration - paused.previouslyElapsedDuration)),
                format: .time(pattern: .hourMinuteSecond))
        case .alert:
            Text("Time's up")
        @unknown default:
            Text("Timer")
        }
    }
}

@main struct TalkingClockWidgets: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        AnnouncementWidget()
    }
}

struct AnnouncementWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AnnouncementActivity.self) { context in
            VStack(alignment: .leading) {
                Text(context.attributes.title)
                Text("Next at \(context.state.nextAnnouncement.formatted(date: .omitted, time: .shortened))")
                Button("Stop announcements", intent: StopAnnouncementsIntent())
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text("Speaking") }
                DynamicIslandExpandedRegion(.trailing) { Text(context.state.nextAnnouncement, style: .time) }
                DynamicIslandExpandedRegion(.bottom) { Button("Stop", intent: StopAnnouncementsIntent()) }
            } compactLeading: {
                Image(systemName: "waveform")
            } compactTrailing: {
                Text(context.state.nextAnnouncement, style: .time)
            } minimal: {
                Image(systemName: "waveform")
            }
        }
    }
}
