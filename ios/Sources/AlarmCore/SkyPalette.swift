import Foundation

/// Halo Ramp's sRGB colors and OKLCH interpolation, independent of SwiftUI for contrast audits.
public struct SkyColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double

    public init(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    private static func linear(_ value: Double) -> Double {
        let value = value / 255
        return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    public var luminance: Double {
        0.2126 * Self.linear(red) + 0.7152 * Self.linear(green) + 0.0722 * Self.linear(blue)
    }

    public func contrast(with other: Self) -> Double {
        (max(luminance, other.luminance) + 0.05) / (min(luminance, other.luminance) + 0.05)
    }

    public func mix(_ other: Self, fraction: Double) -> Self {
        Self(
            red + (other.red - red) * fraction, green + (other.green - green) * fraction,
            blue + (other.blue - blue) * fraction, opacity + (other.opacity - opacity) * fraction)
    }

    private var oklch: (Double, Double, Double) {
        let r = Self.linear(red)
        let g = Self.linear(green)
        let b = Self.linear(blue)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        let lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
        let a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
        let bAxis = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        return (lightness, hypot(a, bAxis), atan2(bAxis, a))
    }

    public func blend(_ other: Self, fraction: Double) -> Self {
        let a = oklch
        let b = other.oklch
        var delta = b.2 - a.2
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }
        let firstHue = a.1 < 0.02 ? b.2 : a.2
        let lastHue = b.1 < 0.02 ? a.2 : a.2 + delta
        let lightness = a.0 + (b.0 - a.0) * fraction
        let chroma = a.1 + (b.1 - a.1) * fraction
        let hue = firstHue + (lastHue - firstHue) * fraction
        let axisA = chroma * cos(hue)
        let axisB = chroma * sin(hue)
        let l = pow(lightness + 0.3963377774 * axisA + 0.2158037573 * axisB, 3)
        let m = pow(lightness - 0.1055613458 * axisA - 0.0638541728 * axisB, 3)
        let s = pow(lightness - 0.0894841775 * axisA - 1.2914855480 * axisB, 3)
        func srgb(_ value: Double) -> Double {
            let value = max(0, value)
            return min(255, 255 * (value <= 0.0031308 ? 12.92 * value : 1.055 * pow(value, 1 / 2.4) - 0.055))
        }
        return Self(
            srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
            srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
            srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
            opacity + (other.opacity - opacity) * fraction)
    }
}

public struct SkyPalette: Sendable {
    public var top: SkyColor
    public var bottom: SkyColor
    public var lights: [SkyColor]
    public var ink: SkyColor

    public var backdrop: SkyColor {
        top.mix(bottom, fraction: 0.5).mix(lights[0], fraction: lights[0].opacity * 0.35)
            .mix(lights[1], fraction: lights[1].opacity * 0.2)
    }

    public static func at(minute: Double, dark: Bool) -> Self {
        let minute = (minute.truncatingRemainder(dividingBy: 1440) + 1440).truncatingRemainder(dividingBy: 1440)
        let stops = dark ? darkStops : lightStops
        let index = stops.lastIndex { $0.0 <= minute } ?? 0
        let a = stops[index]
        let b = stops[index + 1]
        let fraction = (minute - a.0) / (b.0 - a.0)
        let eased = fraction * fraction * (3 - 2 * fraction)
        return Self(
            top: a.1.top.blend(b.1.top, fraction: eased), bottom: a.1.bottom.blend(b.1.bottom, fraction: eased),
            lights: zip(a.1.lights, b.1.lights).map { $0.blend($1, fraction: eased) },
            ink: a.1.ink.mix(b.1.ink, fraction: eased))
    }

    public func eased(toward target: Self, elapsed: Double) -> Self {
        let fraction = 1 - exp(-max(0, elapsed) / 0.5)
        return Self(
            top: top.mix(target.top, fraction: fraction), bottom: bottom.mix(target.bottom, fraction: fraction),
            lights: zip(lights, target.lights).map { $0.mix($1, fraction: fraction) },
            ink: ink.mix(target.ink, fraction: fraction))
    }

    /// Text and panels switch together; hysteresis prevents flicker without a low-contrast crossfade.
    public func tokens(dark: Bool, previousLightText: Bool? = nil) -> SkyTokens {
        let sky = backdrop
        let luminance = sky.luminance
        var lightText = dark || (previousLightText ?? (luminance < 0.213))
        if !dark {
            if lightText && luminance > 0.222 {
                lightText = false
            } else if !lightText && luminance < 0.204 {
                lightText = true
            }
        }
        let text = lightText ? SkyColor(238, 240, 246) : ink
        let opacity = luminance > 0.06 ? (luminance - 0.06) / (luminance - 0.006) : 0
        let blend = min(1, max(0, opacity / 0.15))
        let eased = blend * blend * (3 - 2 * blend)
        var glass =
            lightText ? SkyColor(255, 255, 255).mix(SkyColor(12, 16, 34), fraction: eased) : SkyColor(255, 255, 255)
        glass.opacity = lightText ? 0.075 * (1 - eased) + opacity * eased : 0.55
        let panel = sky.mix(glass, fraction: glass.opacity)
        var secondary = 0.58
        while secondary < 1
            && min(
                sky.mix(text, fraction: secondary).contrast(with: sky),
                panel.mix(text, fraction: secondary).contrast(with: panel)) < 4.5
        {
            secondary += 0.02
        }
        return SkyTokens(
            lightText: lightText, text: text, secondaryOpacity: min(1, secondary), glass: glass,
            edgeOpacity: lightText ? 0.13 : 0.85,
            accent: lightText ? SkyColor(255, 179, 107) : SkyColor(217, 102, 26),
            accentText: lightText ? SkyColor(255, 179, 107) : SkyColor(194, 88, 15),
            onAccent: lightText ? SkyColor(26, 18, 8) : SkyColor(255, 255, 255))
    }

    // Ported from the attached reference; twilight chroma is already softened by 0.50 in these stops.
    private static let lightStops: [(Double, SkyPalette)] = [
        (
            0,
            SkyPalette(
                top: SkyColor(14, 23, 48), bottom: SkyColor(11, 18, 38),
                lights: [SkyColor(31, 74, 94, 0.62), SkyColor(59, 53, 112, 0.5), SkyColor(26, 62, 86, 0.48)],
                ink: SkyColor(16, 35, 58))
        ),
        (
            280,
            SkyPalette(
                top: SkyColor(14, 23, 48), bottom: SkyColor(11, 18, 38),
                lights: [SkyColor(31, 74, 94, 0.62), SkyColor(59, 53, 112, 0.5), SkyColor(26, 62, 86, 0.48)],
                ink: SkyColor(16, 35, 58))
        ),
        (
            310,
            SkyPalette(
                top: SkyColor(31.80195519, 32.65986775, 55.66847727),
                bottom: SkyColor(41.29774916, 38.2926848, 64.19121789),
                lights: [
                    SkyColor(94.14467194, 84.44139406, 132.44934914, 0.55),
                    SkyColor(129.36669186, 90.20575044, 123.03568878, 0.4),
                    SkyColor(161.17266431, 110.78615617, 118.36260172, 0.4),
                ], ink: SkyColor(16, 35, 58))
        ),
        (
            340,
            SkyPalette(
                top: SkyColor(59.08671221, 52.02658262, 84.62892816),
                bottom: SkyColor(105.90046851, 75.82905618, 101.45580004),
                lights: [
                    SkyColor(171.18387215, 120.66172524, 133.42170572, 0.5),
                    SkyColor(115.84226557, 105.07298095, 158.27913188, 0.45),
                    SkyColor(207.8254902, 157.19303402, 141.87808523, 0.6),
                ], ink: SkyColor(42, 31, 46))
        ),
        (
            360,
            SkyPalette(
                top: SkyColor(223.83138479, 191.82743607, 179.27179802),
                bottom: SkyColor(215.26510823, 168.97823985, 158.39991147),
                lights: [
                    SkyColor(233.95429995, 206.43705191, 177.65796491, 0.8),
                    SkyColor(217.95905285, 174.55873816, 178.63424751, 0.7),
                    SkyColor(195.77500771, 186.36016288, 216.37827495, 0.6),
                ], ink: SkyColor(42, 31, 46))
        ),
        (
            420,
            SkyPalette(
                top: SkyColor(251, 239, 234), bottom: SkyColor(244, 228, 230),
                lights: [SkyColor(249, 217, 207, 1), SkyColor(228, 221, 247, 1), SkyColor(246, 214, 208, 0.8)],
                ink: SkyColor(42, 31, 46))
        ),
        (
            510,
            SkyPalette(
                top: SkyColor(238, 245, 251), bottom: SkyColor(232, 241, 248),
                lights: [SkyColor(207, 230, 250, 1), SkyColor(227, 244, 236, 1), SkyColor(217, 236, 247, 0.8)],
                ink: SkyColor(16, 35, 58))
        ),
        (
            960,
            SkyPalette(
                top: SkyColor(238, 245, 251), bottom: SkyColor(232, 241, 248),
                lights: [SkyColor(207, 230, 250, 1), SkyColor(227, 244, 236, 1), SkyColor(217, 236, 247, 0.8)],
                ink: SkyColor(16, 35, 58))
        ),
        (
            1020,
            SkyPalette(
                top: SkyColor(247, 236, 241), bottom: SkyColor(241, 226, 234),
                lights: [SkyColor(246, 210, 221, 1), SkyColor(220, 214, 242, 1), SkyColor(243, 213, 208, 0.8)],
                ink: SkyColor(42, 24, 48))
        ),
        (
            1080,
            SkyPalette(
                top: SkyColor(225.10811889, 199.72141576, 191.13244586),
                bottom: SkyColor(214.30068088, 171.51501693, 162.9591984),
                lights: [
                    SkyColor(230.69339933, 198.19545263, 165.28527452, 0.8),
                    SkyColor(207.16290206, 151.32456498, 159.27444063, 0.6),
                    SkyColor(182.91098165, 168.71419012, 203.60463484, 0.6),
                ], ink: SkyColor(42, 24, 48))
        ),
        (
            1120,
            SkyPalette(
                top: SkyColor(199.38502294, 153.55121699, 149.55499259),
                bottom: SkyColor(184.5157534, 128.51064778, 133.02361671),
                lights: [
                    SkyColor(225.42247122, 182.60410886, 154.26675253, 0.6),
                    SkyColor(195.67105062, 135.2340132, 147.2620378, 0.55),
                    SkyColor(157.83150965, 134.36244249, 178.59193016, 0.5),
                ], ink: SkyColor(42, 17, 36))
        ),
        (
            1140,
            SkyPalette(
                top: SkyColor(67.93520474, 55.38369583, 88.01559654),
                bottom: SkyColor(92.42709527, 64.95797452, 89.08672872),
                lights: [
                    SkyColor(178.61682523, 123.2190914, 135.49096612, 0.45),
                    SkyColor(105.99384865, 95.67219642, 148.54081139, 0.5),
                    SkyColor(195.85262576, 140.48871468, 125.03943776, 0.35),
                ], ink: SkyColor(42, 17, 36))
        ),
        (
            1185,
            SkyPalette(
                top: SkyColor(36.24406488, 34.8127328, 59.67947436),
                bottom: SkyColor(29.83632853, 30.78675793, 51.51592426),
                lights: [
                    SkyColor(80.01108214, 76.68574389, 122.62188894, 0.5),
                    SkyColor(52.64986769, 71.57650373, 81.41357939, 0.5),
                    SkyColor(120.99082817, 86.08762643, 109.5597656, 0.3),
                ], ink: SkyColor(16, 35, 58))
        ),
        (
            1260,
            SkyPalette(
                top: SkyColor(14, 23, 48), bottom: SkyColor(11, 18, 38),
                lights: [SkyColor(31, 74, 94, 0.62), SkyColor(59, 53, 112, 0.5), SkyColor(26, 62, 86, 0.48)],
                ink: SkyColor(16, 35, 58))
        ),
        (
            1440,
            SkyPalette(
                top: SkyColor(14, 23, 48), bottom: SkyColor(11, 18, 38),
                lights: [SkyColor(31, 74, 94, 0.62), SkyColor(59, 53, 112, 0.5), SkyColor(26, 62, 86, 0.48)],
                ink: SkyColor(16, 35, 58))
        ),
    ]
    private static let darkStops: [(Double, SkyPalette)] = [
        (
            0,
            SkyPalette(
                top: SkyColor(5, 7, 13), bottom: SkyColor(3, 4, 9),
                lights: [SkyColor(31, 74, 94, 0.2), SkyColor(59, 53, 112, 0.16), SkyColor(26, 62, 86, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            280,
            SkyPalette(
                top: SkyColor(5, 7, 13), bottom: SkyColor(3, 4, 9),
                lights: [SkyColor(31, 74, 94, 0.2), SkyColor(59, 53, 112, 0.16), SkyColor(26, 62, 86, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            310,
            SkyPalette(
                top: SkyColor(8.61648282, 8.7649292, 18.11408112),
                bottom: SkyColor(9.78000877, 8.73094081, 17.16047926),
                lights: [
                    SkyColor(94.14467194, 84.44139406, 132.44934914, 0.2),
                    SkyColor(129.36669186, 90.20575044, 123.03568878, 0.14),
                    SkyColor(161.17266431, 110.78615617, 118.36260172, 0.12),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            340,
            SkyPalette(
                top: SkyColor(13.55886364, 12.06645194, 20.92050791),
                bottom: SkyColor(18.6687664, 12.39131895, 20.66228696),
                lights: [
                    SkyColor(171.18387215, 120.66172524, 133.42170572, 0.2),
                    SkyColor(115.84226557, 105.07298095, 158.27913188, 0.16),
                    SkyColor(207.8254902, 157.19303402, 141.87808523, 0.16),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            360,
            SkyPalette(
                top: SkyColor(18.95072258, 13.8775104, 16.79270993),
                bottom: SkyColor(16.88521747, 11.79160382, 13.69520864),
                lights: [
                    SkyColor(225.70014451, 182.74755791, 158.63724067, 0.18),
                    SkyColor(213.21332532, 159.78583896, 168.06009221, 0.14),
                    SkyColor(173.51124609, 159.73068571, 199.51115195, 0.12),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            420,
            SkyPalette(
                top: SkyColor(16, 11, 15), bottom: SkyColor(9, 7, 11),
                lights: [SkyColor(122, 74, 70, 0.2), SkyColor(84, 66, 124, 0.16), SkyColor(96, 60, 70, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            510,
            SkyPalette(
                top: SkyColor(7, 11, 17), bottom: SkyColor(5, 7, 11),
                lights: [SkyColor(46, 92, 128, 0.2), SkyColor(44, 96, 84, 0.12), SkyColor(40, 74, 104, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            960,
            SkyPalette(
                top: SkyColor(7, 11, 17), bottom: SkyColor(5, 7, 11),
                lights: [SkyColor(46, 92, 128, 0.2), SkyColor(44, 96, 84, 0.12), SkyColor(40, 74, 104, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            1020,
            SkyPalette(
                top: SkyColor(15, 9, 14), bottom: SkyColor(8, 6, 10),
                lights: [SkyColor(128, 62, 80, 0.2), SkyColor(72, 60, 124, 0.16), SkyColor(110, 56, 48, 0.12)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            1080,
            SkyPalette(
                top: SkyColor(17.04375694, 12.44998464, 12.88116573),
                bottom: SkyColor(13.38916948, 9.25630968, 10.23905704),
                lights: [
                    SkyColor(225.42247122, 182.60410886, 154.26675253, 0.18),
                    SkyColor(204.89721009, 144.27098802, 151.61757639, 0.14),
                    SkyColor(160.89847622, 142.54787521, 186.98970094, 0.12),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            1120,
            SkyPalette(
                top: SkyColor(17.68008805, 12.09496781, 14.97797719),
                bottom: SkyColor(13.24023342, 8.59012213, 11.59088169),
                lights: [
                    SkyColor(205.77859569, 150.16631595, 139.09102463, 0.2),
                    SkyColor(186.49449604, 126.32962601, 143.02877558, 0.16),
                    SkyColor(138.71780651, 116.19996365, 164.89505996, 0.12),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            1140,
            SkyPalette(
                top: SkyColor(12.07417986, 9.91532458, 17.85396565),
                bottom: SkyColor(9.19876397, 7.47329502, 14.43656382),
                lights: [
                    SkyColor(154.56655799, 109.2074664, 127.20571537, 0.18),
                    SkyColor(96.17246998, 86.39057022, 138.84304071, 0.18),
                    SkyColor(169.45865748, 119.16321931, 108.22296415, 0.12),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            1185,
            SkyPalette(
                top: SkyColor(7.39266878, 7.34548044, 15.22012898),
                bottom: SkyColor(5.50812559, 5.79096982, 11.52106118),
                lights: [
                    SkyColor(80.01108214, 76.68574389, 122.62188894, 0.18),
                    SkyColor(52.64986769, 71.57650373, 81.41357939, 0.16),
                    SkyColor(120.99082817, 86.08762643, 109.5597656, 0.12),
                ], ink: SkyColor(238, 240, 246))
        ),
        (
            1260,
            SkyPalette(
                top: SkyColor(5, 7, 13), bottom: SkyColor(3, 4, 9),
                lights: [SkyColor(31, 74, 94, 0.2), SkyColor(59, 53, 112, 0.16), SkyColor(26, 62, 86, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
        (
            1440,
            SkyPalette(
                top: SkyColor(5, 7, 13), bottom: SkyColor(3, 4, 9),
                lights: [SkyColor(31, 74, 94, 0.2), SkyColor(59, 53, 112, 0.16), SkyColor(26, 62, 86, 0.14)],
                ink: SkyColor(238, 240, 246))
        ),
    ]
}

public struct SkyTokens: Sendable {
    public var lightText: Bool
    public var text: SkyColor
    public var secondaryOpacity: Double
    public var glass: SkyColor
    public var edgeOpacity: Double
    public var accent: SkyColor
    public var accentText: SkyColor
    public var onAccent: SkyColor
}
