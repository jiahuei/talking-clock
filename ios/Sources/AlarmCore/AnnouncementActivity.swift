#if canImport(ActivityKit) && os(iOS)
    import ActivityKit
    import AppIntents
    import Foundation

    public struct AnnouncementActivity: ActivityAttributes {
        public struct ContentState: Codable, Hashable {
            public var nextAnnouncement: Date
            public init(nextAnnouncement: Date) { self.nextAnnouncement = nextAnnouncement }
        }
        public var title: String
        public init(title: String) { self.title = title }
    }

    public struct StopAnnouncementsIntent: LiveActivityIntent {
        public static var title: LocalizedStringResource = "Stop announcements"
        public static var openAppWhenRun = true
        public init() {}
        public func perform() async throws -> some IntentResult {
            await MainActor.run {
                NotificationCenter.default.post(name: Notification.Name("StopAnnouncementSpike"), object: nil)
            }
            return .result()
        }
    }
#endif
