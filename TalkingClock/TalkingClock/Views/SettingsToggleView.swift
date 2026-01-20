import SwiftUI

struct SettingsToggleView: View {
    @Binding var showAnalogClock: Bool
    @Binding var isAnnouncementEnabled: Bool

    var body: some View {
        VStack(spacing: 16) {
            Toggle("Show Analog Clock", isOn: $showAnalogClock)
                .toggleStyle(SwitchToggleStyle(tint: .blue))

            Toggle("Auto-Announce Time", isOn: $isAnnouncementEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    SettingsToggleView(
        showAnalogClock: .constant(true),
        isAnnouncementEnabled: .constant(true)
    )
}
