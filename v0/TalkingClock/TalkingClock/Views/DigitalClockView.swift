import SwiftUI

struct DigitalClockView: View {
    let time: Date

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: time)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(timeString)
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .monospacedDigit()

            Text(dateString)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DigitalClockView(time: Date())
}
