import AlarmCore
import SwiftUI

extension SkyColor {
    var color: Color { Color(.sRGB, red: red / 255, green: green / 255, blue: blue / 255, opacity: opacity) }
}

private struct HaloTokensKey: EnvironmentKey {
    static let defaultValue = SkyPalette.at(minute: 720, dark: false).tokens(dark: false)
}

extension EnvironmentValues {
    var halo: SkyTokens {
        get { self[HaloTokensKey.self] }
        set { self[HaloTokensKey.self] = newValue }
    }
}

struct SkyScreen<Content: View>: View {
    var minute: Double?
    @ViewBuilder var content: () -> Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sky = SkyPalette.at(minute: 720, dark: false)
    @State private var tokens = SkyPalette.at(minute: 720, dark: false).tokens(dark: false)
    @State private var drifting = false

    private func target() -> SkyPalette {
        let now = Date()
        let minutes =
            minute
            ?? Double(
                Calendar.current.component(.hour, from: now) * 60 + Calendar.current.component(.minute, from: now))
        return SkyPalette.at(minute: minutes, dark: scheme == .dark)
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(colors: [sky.top.color, sky.bottom.color], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<3) { index in
                        let sizes: [CGSize] = [
                            CGSize(width: 0.62, height: 0.40), CGSize(width: 0.58, height: 0.44),
                            CGSize(width: 0.70, height: 0.38),
                        ]
                        let centers: [UnitPoint] = [
                            UnitPoint(x: 0.14, y: 0.12), UnitPoint(x: 0.92, y: 0.62), UnitPoint(x: 0.38, y: 1.04),
                        ]
                        Ellipse().fill(
                            RadialGradient(
                                colors: [sky.lights[index].color, .clear], center: .center, startRadius: 0,
                                endRadius: geometry.size.width * sizes[index].width * 0.72)
                        )
                        .frame(
                            width: geometry.size.width * sizes[index].width * 2,
                            height: geometry.size.height * sizes[index].height * 2
                        )
                        .position(x: geometry.size.width * centers[index].x, y: geometry.size.height * centers[index].y)
                    }
                }
                .scaleEffect(reduceMotion ? 1.15 : (drifting ? 1.20 : 1.15))
                .offset(
                    x: !reduceMotion && drifting ? -geometry.size.width * 0.04 : 0,
                    y: !reduceMotion && drifting ? geometry.size.height * 0.03 : 0)
            }.ignoresSafeArea().accessibilityHidden(true)
            content().foregroundStyle(tokens.text.color).tint(tokens.accentText.color).environment(\.halo, tokens)
        }
        .task {
            sky = target()
            tokens = sky.tokens(dark: scheme == .dark)
            withAnimation(.easeInOut(duration: 34).repeatForever(autoreverses: true)) { drifting = true }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                sky = sky.eased(toward: target(), elapsed: 1)
                tokens = sky.tokens(dark: scheme == .dark, previousLightText: tokens.lightText)
            }
        }
        .task(id: scheme) {
            // Ease only the sky; text and panel tokens change atomically at the luminance thresholds.
            for _ in 0..<40 {
                sky = sky.eased(toward: target(), elapsed: 0.05)
                tokens = sky.tokens(dark: scheme == .dark, previousLightText: tokens.lightText)
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
            }
        }
    }
}

struct GlassPanel<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.halo) private var palette
    var body: some View {
        content().padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.glass.color, in: RoundedRectangle(cornerRadius: 30))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(palette.edgeOpacity), lineWidth: 1))
    }
}

struct HaloRing<Content: View>: View {
    var progress: Double
    var diameter: CGFloat = 304
    var glowing = false
    @ViewBuilder var content: () -> Content
    @Environment(\.halo) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false
    var body: some View {
        ZStack {
            if glowing {
                Circle().fill(
                    RadialGradient(
                        colors: [palette.accent.color.opacity(0.30), .clear], center: .center, startRadius: 0,
                        endRadius: diameter * 0.65)
                )
                .scaleEffect(reduceMotion ? 1 : (breathing ? 1.22 : 0.96))
            }
            Circle().stroke(palette.text.color.opacity(0.12), lineWidth: 2)
            Circle().trim(from: 0, to: min(1, max(0, progress)))
                .stroke(palette.accent.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .linear(duration: 0.3), value: progress)
            content().padding(24)
        }.frame(width: diameter, height: diameter)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { breathing = true }
            }
    }
}

struct HaloTime: View {
    let date: Date
    var size: CGFloat = 112
    var body: some View {
        let formatter = DateFormatter()
        let _ = formatter.setLocalizedDateFormatFromTemplate("jmm")
        let value = formatter.string(from: date)
        let period = [formatter.amSymbol, formatter.pmSymbol].compactMap { $0 }.first { value.contains($0) }
        VStack(spacing: 0) {
            Text(
                period.map { value.replacingOccurrences(of: $0, with: "").trimmingCharacters(in: .whitespaces) }
                    ?? value
            )
            .font(.system(size: size, weight: .light, design: .serif)).monospacedDigit()
            .tracking(-size * 0.035).lineLimit(1).minimumScaleFactor(0.4)
            if let period { Text(period.lowercased()).font(.system(.title2, design: .serif).italic()) }
        }.accessibilityElement(children: .ignore).accessibilityLabel(date.formatted(date: .omitted, time: .shortened))
    }
}

struct HaloButtonStyle: ButtonStyle {
    var primary = false
    @Environment(\.halo) private var palette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).frame(minHeight: 60)
            .foregroundStyle(primary ? palette.onAccent.color : palette.text.color)
            .background(primary ? palette.accent.color : palette.glass.color, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
