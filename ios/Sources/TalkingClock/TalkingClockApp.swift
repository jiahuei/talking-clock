import AlarmCore
import AlarmKit
import SwiftUI

@main
struct TalkingClockApp: App {
    @State private var store: AlarmStore
    private let audio: AlarmAudio
    @State private var session: AnnouncementSession
    @State private var timer: TimerStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let audio = AlarmAudio()
        self.audio = audio
        _session = State(initialValue: AnnouncementSession(audio: audio))
        _timer = State(initialValue: TimerStore(scheduler: SystemTimerScheduler(audio: audio)))
        let directory = URL.applicationSupportDirectory.appendingPathComponent("TalkingClock", isDirectory: true)
        _store = State(
            initialValue: AlarmStore(
                scheduler: SystemAlarmScheduler(audio: audio),
                repository: FileAlarmRepository(url: directory.appendingPathComponent("alarms.json"))))
    }

    @ViewBuilder private var rootView: some View {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BackgroundSpeechSpike") {
                BackgroundSpeechSpikeView(audio: audio)
            } else {
                productionView
            }
        #else
            productionView
        #endif
    }

    var body: some Scene {
        WindowGroup { rootView }
    }

    private var productionView: some View {
        MainView(store: store, audio: audio, session: session, timer: timer)
            .tint(.orange)
            .task {
                store.refresh()
                timer.refresh()
                for await _ in AlarmManager.shared.alarmUpdates {
                    store.refresh()
                    timer.refresh()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    store.refresh()
                    timer.refresh()
                } else {
                    audio.stop()
                }
                session.updateClock(active: phase == .active)
                session.updateTimer(deadline: timer.countdown.deadline, active: phase == .active)
            }
    }
}
