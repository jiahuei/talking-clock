import Foundation

struct ClockSettings: Codable, Equatable {
    var intervalValue: Int
    var timeUnit: TimeUnit
    var showAnalogClock: Bool
    var isAnnouncementEnabled: Bool

    static let defaultSettings = ClockSettings(
        intervalValue: 5,
        timeUnit: .minutes,
        showAnalogClock: true,
        isAnnouncementEnabled: true
    )

    var intervalInSeconds: TimeInterval {
        timeUnit.intervalInSeconds(intervalValue)
    }
}

// MARK: - UserDefaults Persistence
extension ClockSettings {
    private static let storageKey = "clockSettings"

    static func load() -> ClockSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(ClockSettings.self, from: data) else {
            return .defaultSettings
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: ClockSettings.storageKey)
        }
    }
}
