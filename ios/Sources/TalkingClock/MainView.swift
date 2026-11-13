import AlarmCore
import AlarmKit
import SwiftUI

struct MainView: View {
    @Bindable var store: AlarmStore
    let audio: AlarmAudio
    @Bindable var session: AnnouncementSession
    @Bindable var timer: TimerStore
    @State private var editing: AlarmRecord?
    @State private var deleting: AlarmRecord?
    @State private var cancelling: AlarmRecord?
    @State private var authorizationDenied = AlarmManager.shared.authorizationState == .denied

    var body: some View {
        TabView {
            ClockView(audio: audio, session: session).tabItem { Label("Clock", systemImage: "clock") }
            alarmScreen.tabItem { Label("Alarm", systemImage: "alarm") }
            TimerView(timer: timer, session: session).tabItem { Label("Timer", systemImage: "timer") }
        }
        .sheet(item: $editing) { alarm in AlarmEditor(alarm: alarm, store: store, audio: audio) }
        .fullScreenCover(isPresented: Binding(get: { !store.ringing.isEmpty }, set: { _ in })) {
            if let alarm = store.ringing.first { RingingView(alarm: alarm, store: store) }
        }
        .confirmationDialog(
            deleting.map { "Delete \($0.displayDate().formatted(date: .omitted, time: .shortened)) alarm?" }
                ?? "Delete alarm?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible
        ) {
            if let alarm = deleting {
                Button("Cancel", role: .cancel) { deleting = nil }
                Button("Delete alarm", role: .destructive) { Task { _ = await store.delete(alarm) } }
            }
        } message: {
            if let alarm = deleting { Text("\(alarm.label), \(alarm.repeatDescription().lowercased()).") }
        }
        .confirmationDialog(
            cancelling.map {
                "Cancel the \(($0.fireDate ?? $0.displayDate()).formatted(date: .omitted, time: .shortened)) snooze?"
            } ?? "Cancel snooze?",
            isPresented: Binding(get: { cancelling != nil }, set: { if !$0 { cancelling = nil } }),
            titleVisibility: .visible
        ) {
            if let child = cancelling {
                Button("Keep snooze", role: .cancel) { cancelling = nil }
                Button("Cancel snooze", role: .destructive) { Task { _ = await store.delete(child) } }
            }
        } message: {
            if let child = cancelling,
                let parent = store.records.first(where: { $0.id == child.parentID }),
                !parent.weekdays.isEmpty, parent.isEnabled
            {
                Text("\(parent.label) will still ring at its next scheduled time.")
            } else {
                Text("This alarm won't ring again.")
            }
        }
        .alert(
            "Alarm needs attention",
            isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
        ) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .alert(
            "Speech needs attention",
            isPresented: Binding(get: { session.errorMessage != nil }, set: { if !$0 { session.errorMessage = nil } })
        ) {
            Button("OK") { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
        .task {
            for await state in AlarmManager.shared.authorizationUpdates {
                authorizationDenied = state == .denied
                store.refresh()
            }
        }
    }

    private var alarmScreen: some View {
        SkyScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("Alarms").font(.system(size: 46, weight: .light, design: .serif)).accessibilityAddTraits(
                            .isHeader)
                        Spacer()
                        Button("Add alarm", systemImage: "plus") { editing = AlarmRecord() }
                            .labelStyle(.iconOnly).frame(width: 44, height: 44).glassEffect()
                    }
                    status
                    TimelineView(.periodic(from: .now, by: 30)) { context in nextAlarm(at: context.date) }
                    if store.primaryAlarms.isEmpty {
                        ContentUnavailableView {
                            Label("No alarms yet", systemImage: "alarm")
                        } description: {
                            Text("Add an alarm to hear the time when it rings.")
                        } actions: {
                            Button("Create an alarm") { editing = AlarmRecord() }.buttonStyle(.borderedProminent)
                        }
                    } else {
                        GlassPanel {
                            VStack(spacing: 0) {
                                ForEach(store.primaryAlarms) { alarm in
                                    if alarm.id != store.primaryAlarms.first?.id { Divider() }
                                    alarmRow(alarm)
                                    ForEach(store.records.filter { $0.parentID == alarm.id }) { child in
                                        snoozeRow(child)
                                    }
                                }
                            }.clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    if store.isBusy { ProgressView("Preparing alarm…") }
                }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }.disabled(store.isBusy)
        }
    }

    private func nextAlarm(at date: Date) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Next alarm").font(.caption)
                if let (alarm, next) = store.nextAlarm(after: date) {
                    Text(next, format: .dateTime.hour().minute()).font(
                        .system(size: 54, weight: .light, design: .serif))
                    Text(
                        "\(alarm.label)\(alarm.parentID == nil ? "" : ", snoozed"), in \(SpokenTime.duration(max(60, Int(next.timeIntervalSince(date)) / 60 * 60)))"
                    )
                    .font(.system(.subheadline, design: .serif).italic())
                } else {
                    Text("None").font(.system(size: 54, weight: .light, design: .serif))
                    Text("Turn on an alarm below").font(.subheadline)
                }
            }
        }
    }

    private func alarmRow(_ alarm: AlarmRecord) -> some View {
        HStack(spacing: 12) {
            Button {
                editing = alarm
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.displayDate(), format: .dateTime.hour().minute())
                        .font(.system(size: 34, weight: .light, design: .serif)).monospacedDigit()
                        .opacity(store.isScheduled(alarm) ? 1 : 0.4)
                    Text("\(alarm.label), \(alarm.repeatDescription().lowercased())")
                        .font(.subheadline).multilineTextAlignment(.leading)
                    if store.ringing.contains(where: { $0.id == alarm.id }) {
                        Text("ringing now").font(.caption).foregroundStyle(.tint)
                    }
                }
            }.buttonStyle(.plain).accessibilityLabel(
                "Edit \(alarm.label), \(alarm.displayDate().formatted(date: .omitted, time: .shortened))")
            Spacer(minLength: 0)
            Toggle(
                "\(alarm.label) alarm",
                isOn: Binding(
                    get: { store.isScheduled(alarm) },
                    set: { enabled in
                        var updated = alarm
                        updated.isEnabled = enabled
                        Task { _ = await store.save(updated) }
                    })
            ).labelsHidden().fixedSize()
            Button("Delete alarm", systemImage: "trash", role: .destructive) { deleting = alarm }
                .labelStyle(.iconOnly).frame(width: 44, height: 44)
        }.padding(.vertical, 12)
            .contextMenu { Button("Delete alarm", systemImage: "trash", role: .destructive) { deleting = alarm } }
    }

    private func snoozeRow(_ child: AlarmRecord) -> some View {
        HStack {
            Image(systemName: "arrow.turn.down.right").foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    "Snoozed until \((child.fireDate ?? child.displayDate()).formatted(date: .omitted, time: .shortened))"
                )
                if let date = child.fireDate { Text(date, style: .relative).font(.caption) }
            }.font(.subheadline)
            Spacer()
            Button("Cancel") { cancelling = child }.frame(minWidth: 44, minHeight: 44)
        }.padding(10).background(.tint.opacity(0.1))
            .overlay(alignment: .top) {
                Rectangle().fill(.tint).frame(height: 1).mask {
                    HStack(spacing: 4) { ForEach(0..<60) { _ in Rectangle().frame(width: 4) } }
                }
            }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    @ViewBuilder private var status: some View {
        if store.storageFailed {
            Label(
                "Saved alarms could not be read. Your data is preserved; changes are disabled.",
                systemImage: "externaldrive.badge.exclamationmark"
            )
            .font(.subheadline).foregroundStyle(.red)
        } else if store.needsRecovery {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    "An alarm change is unfinished",
                    systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                Text("Retry to finish saving and synchronize your alarms.").font(.subheadline).foregroundStyle(
                    .secondary)
                Button("Retry sync") { Task { await store.retry() } }.buttonStyle(.bordered)
                Button("Discard change", role: .destructive) { Task { await store.discardChange() } }
                    .font(.subheadline)
            }.padding().frame(maxWidth: .infinity, alignment: .leading).background(
                .orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
        if authorizationDenied {
            VStack(alignment: .leading, spacing: 8) {
                Label("Alarm access is off", systemImage: "bell.slash")
                Text("Allow alarms in Settings, then turn your alarms back on.").font(.subheadline)
                Button("Open Settings") { openSettings() }
            }.padding().background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
    }

}

private struct RingingView: View {
    let alarm: AlarmRecord
    @Bindable var store: AlarmStore
    var body: some View {
        SkyScreen(minute: Double(alarm.hour * 60 + alarm.minute)) {
            ScrollView {
                VStack(spacing: 24) {
                    Label("Alarm", systemImage: "bell").font(.title3.weight(.medium))
                    Text(alarm.label).font(.system(size: 34, weight: .light, design: .serif).italic())
                    HaloRing(progress: 1, glowing: true) { HaloTime(date: alarm.displayDate()) }
                    Text(SpokenTime.alarm(alarm)).font(.title3).multilineTextAlignment(.center)
                    HStack(spacing: 10) {
                        Button("Snooze \(alarm.snoozeMinutes) min") { Task { _ = await store.snooze(alarm) } }
                            .buttonStyle(HaloButtonStyle())
                        Button("Stop") { Task { _ = await store.stop(alarm) } }
                            .buttonStyle(HaloButtonStyle(primary: true))
                    }.disabled(store.isBusy)
                    if let error = store.errorMessage { Text(error).font(.footnote) }
                }.padding(20).frame(maxWidth: 540).frame(maxWidth: .infinity)
            }
        }.interactiveDismissDisabled()
    }
}
