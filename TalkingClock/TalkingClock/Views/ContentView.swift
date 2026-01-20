import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ClockViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Analog clock (optional)
                if viewModel.settings.showAnalogClock {
                    AnalogClockView(time: viewModel.currentTime)
                        .frame(width: 200, height: 200)
                        .transition(.opacity.combined(with: .scale))
                }

                // Digital clock
                DigitalClockView(time: viewModel.currentTime)

                // Interval picker
                IntervalPickerView(
                    intervalValue: Binding(
                        get: { viewModel.settings.intervalValue },
                        set: { viewModel.updateIntervalValue($0) }
                    ),
                    timeUnit: Binding(
                        get: { viewModel.settings.timeUnit },
                        set: { viewModel.updateTimeUnit($0) }
                    )
                )
                .padding(.top, 16)

                // Settings toggles
                SettingsToggleView(
                    showAnalogClock: Binding(
                        get: { viewModel.settings.showAnalogClock },
                        set: { _ in viewModel.toggleAnalogClock() }
                    ),
                    isAnnouncementEnabled: Binding(
                        get: { viewModel.settings.isAnnouncementEnabled },
                        set: { _ in viewModel.toggleAnnouncement() }
                    )
                )
                .padding(.top, 8)

                // Manual speak button
                Button(action: {
                    viewModel.speakCurrentTime()
                }) {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Speak Time")
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.top, 16)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.settings.showAnalogClock)
        .onAppear {
            viewModel.requestNotificationPermission()
        }
    }
}

#Preview {
    ContentView()
}
