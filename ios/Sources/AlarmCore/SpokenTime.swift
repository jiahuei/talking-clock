import Foundation

/// English phrases shared by visible text, previews and prepared alarm sounds.
public enum SpokenTime {
    public static func clock(hour: Int, minute: Int, includesIntroduction: Bool = true) -> String {
        let spokenHour = minute == 45 ? (hour + 1) % 24 : hour
        let hourWords = words((spokenHour + 11) % 12 + 1)
        let time: String
        switch minute {
        case 0: time = "\(hourWords) o'clock"
        case 15: time = "quarter past \(hourWords)"
        case 30: time = "half past \(hourWords)"
        case 45: time = "quarter to \(hourWords)"
        case 1...9: time = "\(hourWords) oh \(words(minute))"
        default: time = "\(hourWords) \(words(minute))"
        }
        let period: String
        switch spokenHour {
        case 5..<12: period = "in the morning"
        case 12..<17: period = "in the afternoon"
        case 17..<21: period = "in the evening"
        default: period = "at night"
        }
        let sentence = "\(time) \(period)."
        return includesIntroduction ? "It's \(sentence)" : capitalized(sentence)
    }

    public static func alarm(_ alarm: AlarmRecord) -> String {
        let label = alarm.label.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = label.isEmpty ? "" : " \(label)\(".!?".contains(label.last!) ? "" : ".")"
        return clock(hour: alarm.hour, minute: alarm.minute) + suffix
    }

    public static func duration(_ seconds: Int) -> String {
        let parts = [(seconds / 3600, "hour"), (seconds % 3600 / 60, "minute"), (seconds % 60, "second")]
        return parts.filter { $0.0 > 0 }.map { count, unit in
            "\(words(count)) \(unit)\(count == 1 ? "" : "s")"
        }.joined(separator: " ")
    }

    public static func remaining(_ seconds: Int) -> String {
        seconds <= 0 ? "Time's up." : capitalized(duration(seconds) + " left.")
    }

    private static func words(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .spellOut
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
