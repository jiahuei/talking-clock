import XCTest

@testable import AlarmCore

final class SkyPaletteTests: XCTestCase {
    /// Ensures the Swift port retains the reference's measured minimum contrast across every six seconds of a day.
    func testDayLongContrastAudit() {
        for dark in [false, true] {
            var previous: Bool?
            var skyMinimum = Double.infinity
            var panelMinimum = Double.infinity
            var secondaryMinimum = Double.infinity
            for minute in stride(from: 0.0, to: 1440, by: 0.1) {
                let sky = SkyPalette.at(minute: minute, dark: dark)
                let tokens = sky.tokens(dark: dark, previousLightText: previous)
                previous = tokens.lightText
                let backdrop = sky.backdrop
                let panel = backdrop.mix(tokens.glass, fraction: tokens.glass.opacity)
                skyMinimum = min(skyMinimum, tokens.text.contrast(with: backdrop))
                panelMinimum = min(panelMinimum, tokens.text.contrast(with: panel))
                secondaryMinimum = min(
                    secondaryMinimum, panel.mix(tokens.text, fraction: tokens.secondaryOpacity).contrast(with: panel))
            }
            XCTAssertGreaterThanOrEqual(skyMinimum, dark ? 5.08 : 3.40)
            XCTAssertGreaterThanOrEqual(panelMinimum, dark ? 5.08 : 6.7)
            XCTAssertGreaterThanOrEqual(secondaryMinimum, 4.5)
        }
    }

    /// Ensures the sky wraps continuously at midnight and text tokens never interpolate through grey.
    func testMidnightAndDiscreteText() {
        for dark in [false, true] {
            XCTAssertEqual(SkyPalette.at(minute: 0, dark: dark).top, SkyPalette.at(minute: 1440, dark: dark).top)
            var previous: Bool?
            for minute in stride(from: 340.0, to: 360, by: 0.1) {
                let sky = SkyPalette.at(minute: minute, dark: dark)
                let tokens = sky.tokens(dark: dark, previousLightText: previous)
                previous = tokens.lightText
                XCTAssertEqual(tokens.text, tokens.lightText ? SkyColor(238, 240, 246) : sky.ink)
            }
        }
    }
}
