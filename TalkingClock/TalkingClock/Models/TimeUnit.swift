import Foundation

enum TimeUnit: String, Codable, CaseIterable {
    case seconds
    case minutes

    var displayName: String {
        switch self {
        case .seconds:
            return "seconds"
        case .minutes:
            return "minutes"
        }
    }

    var availableIntervals: [Int] {
        switch self {
        case .seconds:
            return [10, 20, 30]
        case .minutes:
            return [1, 2, 5, 10, 15, 30]
        }
    }

    func intervalInSeconds(_ value: Int) -> TimeInterval {
        switch self {
        case .seconds:
            return TimeInterval(value)
        case .minutes:
            return TimeInterval(value * 60)
        }
    }
}
