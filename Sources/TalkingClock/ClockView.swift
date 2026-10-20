import AlarmCore
import SwiftUI

struct ClockView: View {
    let audio: AlarmAudio
    @Bindable var store: AlarmStore

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView {
                    VStack(spacing: 28) {
                        Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        ClockFace(date: context.date).frame(maxWidth: 300).aspectRatio(1, contentMode: .fit)
                            .accessibilityHidden(true)
                        Text(context.date, format: .dateTime.hour().minute())
                            .font(.system(.largeTitle, design: .rounded, weight: .light)).monospacedDigit()
                            .accessibilityAddTraits(.updatesFrequently)
                        Text(TimeZone.current.localizedName(for: .generic, locale: .current) ?? TimeZone.current.identifier)
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button {
                            do { try audio.speakNow() } catch { store.errorMessage = error.localizedDescription }
                        } label: {
                            Label("Speak the time", systemImage: "waveform").padding(.horizontal, 20).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                        Text("A moment, just for now.").font(.footnote).foregroundStyle(.secondary)
                    }.padding(32).frame(maxWidth: 680).frame(maxWidth: .infinity)
                }
            }
            .background(Color(.systemGroupedBackground)).navigationTitle("Now")
        }
    }
}

private struct ClockFace: View {
    let date: Date
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            let face = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.fill(face, with: .color(Color(.secondarySystemGroupedBackground)))
            for mark in 0..<60 {
                let angle = Double(mark) * .pi / 30 - .pi / 2
                let outer = radius - 15
                let inner = outer - (mark % 5 == 0 ? 13.0 : 5.0)
                var tick = Path()
                tick.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                tick.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                context.stroke(tick, with: .color(.secondary.opacity(mark % 5 == 0 ? 0.8 : 0.3)), lineWidth: mark % 5 == 0 ? 2 : 1)
            }
            let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            let minutes = Double(parts.minute ?? 0)
            let hourAngle = (Double((parts.hour ?? 0) % 12) + minutes / 60) * .pi / 6 - .pi / 2
            let minuteAngle = minutes * .pi / 30 - .pi / 2
            let secondAngle = Double(parts.second ?? 0) * .pi / 30 - .pi / 2
            for (angle, length, width, color) in [
                (hourAngle, radius * 0.48, 6.0, Color.primary),
                (minuteAngle, radius * 0.7, 4.0, Color.primary),
                (secondAngle, radius * 0.76, 1.5, Color.orange),
            ] {
                var hand = Path()
                hand.move(to: center)
                hand.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                context.stroke(hand, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            context.fill(Path(ellipseIn: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)), with: .color(.orange))
        }
    }
}
