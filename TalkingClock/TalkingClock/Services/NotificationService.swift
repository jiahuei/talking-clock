import UserNotifications
import AVFoundation

class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let categoryIdentifier = "TIME_ANNOUNCEMENT"

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    func scheduleTimeAnnouncements(intervalSeconds: TimeInterval, enabled: Bool) {
        // Cancel existing notifications first
        cancelAllNotifications()

        guard enabled else { return }

        // Schedule notifications for the next hour
        let now = Date()
        let calendar = Calendar.current

        // Calculate the next aligned time based on interval
        var nextAnnouncementDate = calculateNextAlignedTime(from: now, intervalSeconds: intervalSeconds)

        // Schedule up to 60 notifications (iOS limit is 64 pending)
        for i in 0..<60 {
            let identifier = "time_announcement_\(i)"

            let content = UNMutableNotificationContent()
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let timeString = formatter.string(from: nextAnnouncementDate)

            content.title = "Time Announcement"
            content.body = "The time is \(timeString)"
            content.sound = .default
            content.categoryIdentifier = categoryIdentifier

            let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextAnnouncementDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }

            nextAnnouncementDate = nextAnnouncementDate.addingTimeInterval(intervalSeconds)
        }
    }

    private func calculateNextAlignedTime(from date: Date, intervalSeconds: TimeInterval) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

        guard let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return date.addingTimeInterval(intervalSeconds)
        }

        let totalSeconds = hour * 3600 + minute * 60 + second
        let intervalInt = Int(intervalSeconds)

        // Find the next aligned time
        let nextAlignedSeconds = ((totalSeconds / intervalInt) + 1) * intervalInt
        let secondsUntilNext = nextAlignedSeconds - totalSeconds

        return date.addingTimeInterval(TimeInterval(secondsUntilNext))
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
}
