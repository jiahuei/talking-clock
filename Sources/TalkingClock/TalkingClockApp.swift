import AlarmCore
import AlarmKit
import SwiftUI

@main
struct TalkingClockApp: App {
    @State private var store: AlarmStore
    private let audio: AlarmAudio
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let audio = AlarmAudio()
        self.audio = audio
        let directory = URL.applicationSupportDirectory.appendingPathComponent("TalkingClock", isDirectory: true)
        _store = State(initialValue: AlarmStore(scheduler: SystemAlarmScheduler(audio: audio),
                                                repository: FileAlarmRepository(url: directory.appendingPathComponent("alarms.json"))))
    }

    var body: some Scene {
        WindowGroup {
            MainView(store: store, audio: audio)
                .tint(.orange)
                .task {
                    store.refresh()
                    for await _ in AlarmManager.shared.alarmUpdates { store.refresh() }
                }
                .task {
                    for await _ in AlarmManager.shared.authorizationUpdates { store.refresh() }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.refresh() }
                    else { audio.stop() }
                }
        }
    }
}
