import AlarmCore
import SwiftUI

struct AlarmEditor: View {
    @State var alarm: AlarmRecord
    @Bindable var store: AlarmStore
    let audio: AlarmAudio
    @Environment(\.dismiss) private var dismiss
    @State private var previewing = false
    @State private var message: String?

    private var time: Binding<Date> {
        Binding(get: { alarm.displayDate() }, set: { date in
            alarm.hour = Calendar.current.component(.hour, from: date)
            alarm.minute = Calendar.current.component(.minute, from: date)
        })
    }
    private var orderedDays: [Int] {
        let first = Calendar.current.firstWeekday
        return (0..<7).map { (first - 1 + $0) % 7 + 1 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Alarm time", selection: time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel).labelsHidden().frame(maxWidth: .infinity)
                    TextField("Label", text: $alarm.label).textInputAutocapitalization(.sentences)
                    Toggle("Alarm enabled", isOn: $alarm.isEnabled)
                }
                Section {
                    Picker("Quick repeat", selection: Binding(get: { repeatPreset }, set: { value in
                        switch value {
                        case 1: alarm.weekdays = Set(1...7)
                        case 2: alarm.weekdays = Set(2...6)
                        case 3: alarm.weekdays = [1, 7]
                        default: alarm.weekdays = []
                        }
                    })) {
                        Text("Once").tag(0)
                        Text("Every day").tag(1)
                        Text("Weekdays").tag(2)
                        Text("Weekends").tag(3)
                        if repeatPreset == 4 { Text("Custom").tag(4) }
                    }
                    ForEach(orderedDays, id: \.self) { day in
                        Toggle(DateFormatter().weekdaySymbols[day - 1], isOn: Binding(
                            get: { alarm.weekdays.contains(day) },
                            set: { if $0 { alarm.weekdays.insert(day) } else { alarm.weekdays.remove(day) } }
                        ))
                    }
                } header: { Text("Repeat") } footer: {
                    Text("With no days selected, the alarm rings once at the next occurrence of this time.")
                }
                Section {
                    Toggle("Announce the time", isOn: $alarm.announcesTime)
                    if alarm.announcesTime {
                        Button {
                            previewing = true
                            Task {
                                defer { previewing = false }
                                do { try await audio.preview(alarm) }
                                catch { message = error.localizedDescription }
                            }
                        } label: {
                            Label(previewing ? "Preparing preview…" : "Preview chime & voice", systemImage: "play.circle.fill")
                        }.disabled(previewing)
                        Button("Stop preview", systemImage: "stop.circle") { audio.stop() }
                    }
                    Stepper("Snooze: \(alarm.snoozeMinutes) minutes", value: $alarm.snoozeMinutes, in: 1...30)
                } header: { Text("Sound & snooze") } footer: {
                    Text(alarm.announcesTime
                         ? "An English voice announces the scheduled time, even when the app is closed. Open the app from the system alarm to snooze."
                         : "Plays the system alarm sound. Open the app from the system alarm to snooze.")
                }
            }
            .navigationTitle(store.records.contains(where: { $0.id == alarm.id }) ? "Edit alarm" : "New alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        audio.stop()
                        Task {
                            if await store.save(alarm) { dismiss() }
                            else { message = store.errorMessage; store.errorMessage = nil }
                        }
                    }.bold().disabled(previewing || store.isBusy || store.needsRecovery || store.storageFailed)
                }
            }
            .disabled(store.isBusy)
            .interactiveDismissDisabled(store.isBusy || previewing)
            .overlay {
                if store.isBusy { ProgressView("Saving alarm…").padding().background(.regularMaterial, in: Capsule()) }
            }
            .alert("Couldn’t prepare alarm", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
            .onDisappear { audio.stop() }
        }
    }

    private var repeatPreset: Int {
        if alarm.weekdays.isEmpty { return 0 }
        if alarm.weekdays.count == 7 { return 1 }
        if alarm.weekdays == Set(2...6) { return 2 }
        if alarm.weekdays == [1, 7] { return 3 }
        return 4
    }
}
