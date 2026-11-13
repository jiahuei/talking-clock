import AlarmCore
import SwiftUI

struct TimerView: View {
    @Bindable var timer: TimerStore
    @Bindable var session: AnnouncementSession
    @Environment(\.scenePhase) private var phase
    @State private var custom = false
    @State private var usesCustom = false

    var body: some View {
        SkyScreen {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Text("Timer").font(.system(size: 46, weight: .light, design: .serif))
                            Spacer()
                            Text(timer.countdown.state.rawValue.capitalized).font(.subheadline)
                        }
                        HaloRing(
                            progress: Double(timer.countdown.remaining(at: context.date))
                                / Double(timer.countdown.duration), diameter: 272
                        ) {
                            VStack(spacing: 10) {
                                Text(digits(timer.countdown.remaining(at: context.date)))
                                    .font(.system(size: 92, weight: .light, design: .serif)).monospacedDigit()
                                    .lineLimit(1).minimumScaleFactor(0.3)
                                Text("of \(SpokenTime.duration(timer.countdown.duration))")
                                    .font(.system(.title3, design: .serif).italic()).multilineTextAlignment(.center)
                                    .lineLimit(2).minimumScaleFactor(0.6)
                            }.accessibilityElement(children: .ignore)
                                .accessibilityLabel(SpokenTime.remaining(timer.countdown.remaining(at: context.date)))
                        }
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 5) { presets }
                            VStack { HStack { presets } }.font(.caption)
                        }.disabled(timer.countdown.state == .running || timer.isBusy)
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Say what's left every").font(.subheadline)
                                Picker("Say what's left every", selection: $session.timerInterval) {
                                    Text("30 s").tag(30)
                                    Text("1 min").tag(60)
                                    Text("5 min").tag(300)
                                }.pickerStyle(.segmented)
                                Text("Keep the app open for interval speech. The final alert uses the system alarm.")
                                    .font(.footnote)
                            }
                        }
                        HStack(spacing: 10) {
                            Button("Reset") { timer.reset() }.buttonStyle(HaloButtonStyle())
                            Button(buttonTitle) {
                                if timer.countdown.state == .running {
                                    timer.pause()
                                } else {
                                    Task { await timer.start() }
                                }
                            }.buttonStyle(HaloButtonStyle(primary: true)).frame(maxWidth: .infinity)
                        }.disabled(timer.isBusy)
                        if timer.isBusy { ProgressView("Preparing timer…") }
                    }.padding(20).frame(maxWidth: 540).frame(maxWidth: .infinity)
                }.onChange(of: context.date) { _, _ in timer.refresh() }
            }
        }
        .sheet(isPresented: $custom) {
            CustomTimerPicker(duration: timer.countdown.duration) { seconds in
                timer.setDuration(seconds)
                usesCustom = true
            }
        }
        .onChange(of: timer.countdown.deadline) { _, deadline in
            session.updateTimer(deadline: deadline, active: phase == .active)
        }
        .onChange(of: session.timerInterval) { _, _ in
            session.updateTimer(deadline: timer.countdown.deadline, active: phase == .active)
        }
        .alert(
            "Timer needs attention",
            isPresented: Binding(get: { timer.errorMessage != nil }, set: { if !$0 { timer.errorMessage = nil } })
        ) {
            Button("OK") { timer.errorMessage = nil }
        } message: {
            Text(timer.errorMessage ?? "")
        }
    }

    @ViewBuilder private var presets: some View {
        ForEach([1, 5, 10, 25], id: \.self) { minutes in
            Button("\(minutes) min") {
                timer.setDuration(minutes * 60)
                usesCustom = false
            }
            .buttonStyle(.bordered).buttonBorderShape(.capsule)
            .font(.caption).fixedSize()
            .accessibilityAddTraits(!usesCustom && timer.countdown.duration == minutes * 60 ? .isSelected : [])
        }
        Button(usesCustom ? digits(timer.countdown.duration) : "Custom") { custom = true }
            .buttonStyle(.bordered).buttonBorderShape(.capsule).font(.caption).fixedSize()
            .accessibilityAddTraits(usesCustom ? .isSelected : [])
    }

    private var buttonTitle: String {
        switch timer.countdown.state {
        case .ready: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .done: return "Restart"
        }
    }

    private func digits(_ seconds: Int) -> String {
        seconds >= 3600
            ? String(format: "%d:%02d:%02d", seconds / 3600, seconds % 3600 / 60, seconds % 60)
            : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct CustomTimerPicker: View {
    @State var duration: Int
    let set: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState private var minuteFocused: Bool
    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 0) {
                    wheel("Hours", divisor: 3600, range: 0..<24)
                    wheel("Minutes", divisor: 60, range: 0..<60).accessibilityFocused($minuteFocused)
                    wheel("Seconds", divisor: 1, range: 0..<60)
                }
                Text(duration == 0 ? "Choose a length" : SpokenTime.duration(duration))
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .navigationTitle("Set timer").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set timer") {
                        set(duration)
                        dismiss()
                    }.disabled(duration == 0)
                }
            }.onAppear { minuteFocused = true }
        }.presentationDetents([.medium])
    }

    private func wheel(_ label: String, divisor: Int, range: Range<Int>) -> some View {
        Picker(
            label,
            selection: Binding(
                get: { duration / divisor % (divisor == 3600 ? 24 : 60) },
                set: { duration += ($0 - duration / divisor % (divisor == 3600 ? 24 : 60)) * divisor })
        ) {
            ForEach(range, id: \.self) { Text("\($0)").tag($0) }
        }.pickerStyle(.wheel).frame(maxWidth: .infinity).clipped().accessibilityLabel(label)
    }
}
