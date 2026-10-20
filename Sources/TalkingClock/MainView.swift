import AlarmCore
import AlarmKit
import SwiftUI

struct MainView: View {
    @Bindable var store: AlarmStore
    let audio: AlarmAudio
    @State private var editing: AlarmRecord?
    @State private var deleting: AlarmRecord?

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("A gentler start.\nRight on time.")
                            .font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                        status
                        TimelineView(.periodic(from: .now, by: 30)) { context in nextAlarm(at: context.date) }
                        if !store.ringing.isEmpty { ringingControls }
                        HStack {
                            Text("YOUR ALARMS").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(store.primaryAlarms.count)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        if store.primaryAlarms.isEmpty {
                            ContentUnavailableView {
                                Label("Make room for morning", systemImage: "sun.horizon")
                            } description: {
                                Text("Set an alarm and let a familiar voice tell you the time.")
                            } actions: {
                                Button("Create your first alarm") { editing = AlarmRecord() }.buttonStyle(.borderedProminent)
                            }
                        }
                        ForEach(store.primaryAlarms) { alarm in alarmCard(alarm) }
                        ForEach(store.records.filter { $0.parentID != nil }) { alarm in
                            HStack {
                                Label("Snoozed until \(alarm.fireDate?.formatted(date: .omitted, time: .shortened) ?? "")", systemImage: "zzz")
                                Spacer()
                                Button("Cancel") { Task { _ = await store.delete(alarm) } }
                            }.font(.subheadline).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .frame(maxWidth: 680).padding(24).frame(maxWidth: .infinity)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Talking Clock").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add alarm", systemImage: "plus") { editing = AlarmRecord() }
                    }
                }
            }
            .tabItem { Label("Alarms", systemImage: "alarm") }
            ClockView(audio: audio, store: store)
                .tabItem { Label("Clock", systemImage: "clock") }
            settings.tabItem { Label("About", systemImage: "waveform") }
        }
        .sheet(item: $editing) { alarm in AlarmEditor(alarm: alarm, store: store, audio: audio) }
        .confirmationDialog("Delete this alarm?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            if let alarm = deleting {
                Button("Delete alarm", role: .destructive) { Task { _ = await store.delete(alarm); deleting = nil } }
            }
        } message: { Text("This also cancels any snoozes for this alarm.") }
        .disabled(store.isBusy)
        .overlay {
            if store.isBusy {
                ProgressView("Preparing alarm…").padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .alert("Alarm needs attention", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "") }
    }

    @ViewBuilder private var status: some View {
        if store.storageFailed {
            Label("Saved alarms could not be read. Your data is preserved; changes are disabled.", systemImage: "externaldrive.badge.exclamationmark")
                .font(.subheadline).foregroundStyle(.red)
        } else if store.needsRecovery {
            VStack(alignment: .leading, spacing: 10) {
                Label("An alarm change is unfinished", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                Text("Retry to finish saving and synchronize your alarms.").font(.subheadline).foregroundStyle(.secondary)
                Button("Retry sync") { Task { await store.retry() } }.buttonStyle(.bordered)
            }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
        if AlarmManager.shared.authorizationState == .denied {
            VStack(alignment: .leading, spacing: 8) {
                Label("Alarm access is off", systemImage: "bell.slash")
                Text("Allow alarms in Settings, then turn your alarms back on.").font(.subheadline)
                Button("Open Settings") { openSettings() }
            }.padding().background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func nextAlarm(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("UP NEXT", systemImage: "sun.max.fill").font(.caption.weight(.semibold))
            if let (alarm, next) = store.nextAlarm(after: date) {
                Text(next, format: .dateTime.hour().minute()).font(.system(.largeTitle, design: .rounded, weight: .semibold))
                Text("\(alarm.label) · \(next.formatted(.dateTime.weekday(.wide)))").font(.subheadline)
                Text(next, style: .relative).font(.caption.monospacedDigit()) + Text(" from now").font(.caption)
            } else {
                Text("No alarms ahead").font(.title2.weight(.semibold))
                Text("Your next beginning is up to you.").font(.subheadline)
            }
        }
        .foregroundStyle(Color(.label))
        .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        .background(LinearGradient(colors: [.orange.opacity(0.25), .yellow.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 28))
    }

    private func alarmCard(_ alarm: AlarmRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                Button { editing = alarm } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(alarm.displayDate(), format: .dateTime.hour().minute())
                            .font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit()
                        Text(alarm.label).font(.headline)
                    }.foregroundStyle(.primary).multilineTextAlignment(.leading)
                }.buttonStyle(.plain).accessibilityLabel("Edit \(alarm.label), \(alarm.displayDate().formatted(date: .omitted, time: .shortened))")
                Spacer(minLength: 0)
                Toggle("Enable \(alarm.label)", isOn: Binding(get: { store.isScheduled(alarm) }, set: { enabled in
                    var updated = alarm
                    updated.isEnabled = enabled
                    Task { _ = await store.save(updated) }
                })).labelsHidden().fixedSize()
            }
            ViewThatFits(in: .horizontal) {
                HStack { alarmDetails(alarm); Spacer(); deleteButton(alarm) }
                VStack(alignment: .leading) { alarmDetails(alarm); deleteButton(alarm) }
            }
        }
        .padding(22).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26))
    }

    private func alarmDetails(_ alarm: AlarmRecord) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(alarm.repeatDescription()).font(.subheadline).foregroundStyle(.secondary)
            Label(alarm.announcesTime ? "Speaks the time" : "System sound", systemImage: alarm.announcesTime ? "waveform" : "bell")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
    private func deleteButton(_ alarm: AlarmRecord) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) { deleting = alarm }
            .font(.subheadline).padding(.vertical, 8)
    }

    private var ringingControls: some View {
        ForEach(store.ringing) { alarm in
            VStack(alignment: .leading, spacing: 16) {
                Label("\(alarm.label) is ringing", systemImage: "alarm.waves.left.and.right.fill").font(.title3.bold())
                HStack {
                    Button("Snooze \(alarm.snoozeMinutes) min") { Task { _ = await store.snooze(alarm) } }.buttonStyle(.borderedProminent)
                    Button("Stop", role: .destructive) { Task { _ = await store.stop(alarm) } }.buttonStyle(.bordered)
                }
            }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 22))
        }
    }

    private var settings: some View {
        NavigationStack {
            Form {
                Section("A voice for your morning") {
                    Label("Spoken time in English", systemImage: "waveform")
                    Text("Your alarm sound combines a gentle chime with its scheduled time. Preview it in the alarm editor.")
                    Text("The recording says the scheduled time. It does not update while the alarm rings.")
                }
                Section("Make it yours") {
                    Text("Choose repeat days and snooze length for each alarm. Open Talking Clock from the system alarm to snooze; use Stop on the system alert to dismiss it.")
                    Text("Use your iPhone’s alarm volume. Test an alarm with your device locked before relying on it.")
                    Button("Open system settings") { openSettings() }
                }
                Section("Private by design") {
                    Label("On your device. No account. No tracking.", systemImage: "lock.shield")
                    Link("Support", destination: URL(string: "https://github.com/jiahuei/ios-talking-clock/issues")!)
                }
            }.navigationTitle("Good to know")
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
