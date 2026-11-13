import AlarmCore
import SwiftUI

struct ClockView: View {
    let audio: AlarmAudio
    @Bindable var session: AnnouncementSession
    @State private var showingAbout = false
    @Environment(\.scenePhase) private var phase

    var body: some View {
        SkyScreen {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView {
                    VStack(spacing: 28) {
                        HStack {
                            Text(context.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                                .font(.title3.weight(.medium)).accessibilityAddTraits(.isHeader)
                            Spacer()
                            Button("About", systemImage: "info.circle") { showingAbout = true }
                                .labelStyle(.iconOnly).frame(width: 44, height: 44).glassEffect()
                        }
                        Button {
                            speak()
                        } label: {
                            HaloRing(progress: progress(at: context.date), glowing: audio.isSpeaking) {
                                HaloTime(date: context.date)
                            }
                        }.buttonStyle(.plain).accessibilityLabel(phrase(at: context.date, introduction: true))
                        Text(phrase(at: context.date, introduction: false))
                            .font(.system(.title2, design: .serif).italic()).multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Speak the time every").font(.subheadline)
                                Picker("Speak the time every", selection: $session.clockMinutes) {
                                    ForEach(IntervalScheduler.clockMinutes, id: \.self) { minutes in
                                        Text(minutes == 60 ? "1 hour" : "\(minutes) min").tag(minutes)
                                    }
                                    Text("Off").tag(0)
                                }.pickerStyle(.segmented)
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let next = session.nextClock {
                                            Text("Next at \(next.formatted(date: .omitted, time: .shortened))")
                                            Text(
                                                "in \(max(1, Int(ceil(next.timeIntervalSince(context.date) / 60)))) min"
                                            ).font(.caption)
                                        } else {
                                            Text("Speaking is off")
                                            Text("Tap the time to hear it").font(.caption)
                                        }
                                    }
                                    Spacer()
                                    Button(
                                        audio.isSpeaking ? "Stop" : "Say the time",
                                        systemImage: audio.isSpeaking ? "stop.fill" : "waveform"
                                    ) {
                                        if audio.isSpeaking { audio.stop() } else { speak() }
                                    }.labelStyle(.iconOnly).buttonStyle(.borderedProminent).buttonBorderShape(.circle)
                                        .controlSize(.large)
                                }
                                Text("Keep the app open for interval speech.")
                                    .font(.footnote)
                            }
                        }
                    }.padding(20).frame(maxWidth: 540).frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showingAbout) { AboutView() }
        .onChange(of: session.clockMinutes) { _, _ in session.updateClock(active: phase == .active) }
    }

    private func speak() {
        Task { do { try await audio.speakNow() } catch { session.errorMessage = error.localizedDescription } }
    }

    private func phrase(at date: Date, introduction: Bool) -> String {
        SpokenTime.clock(
            hour: Calendar.current.component(.hour, from: date),
            minute: Calendar.current.component(.minute, from: date), includesIntroduction: introduction)
    }

    private func progress(at date: Date) -> Double {
        guard let next = session.nextClock, session.clockMinutes > 0 else { return 0 }
        return 1 - next.timeIntervalSince(date) / Double(session.clockMinutes * 60)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("How it speaks") {
                    Text(
                        "Clock, Alarm and Timer can each say their time aloud. Clock and Timer interval speech currently requires the app to remain open."
                    )
                    Text("System alarms use a recording of their scheduled time and label. Open the app to snooze.")
                    Text(
                        "Use your iPhone's alarm volume, and test an alarm with your iPhone locked before relying on it."
                    )
                }
                Section("Private by design") {
                    Text("Everything stays on your iPhone. No account, no tracking.")
                    NavigationLink("Privacy Policy") {
                        ScrollView {
                            Text(
                                "Talking Clock stores alarms and generated speech on your device. It does not collect analytics, create accounts, or send your alarm data to a server. Deleting the app removes its local data. Support links open GitHub in your browser, where GitHub's privacy policy applies."
                            )
                            .padding()
                        }.navigationTitle("Privacy Policy")
                    }
                    Link("Support", destination: URL(string: "https://github.com/jiahuei/talking-clock/issues")!)
                }
            }.navigationTitle("About")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.presentationDetents([.large])
    }
}
