import Foundation
import Combine

class ClockViewModel: ObservableObject {
    @Published var currentTime: Date = Date()
    @Published var settings: ClockSettings {
        didSet {
            settings.save()
            rescheduleNotifications()
        }
    }
    @Published var notificationsAuthorized: Bool = false

    private var timer: Timer?
    private var lastAnnouncementTime: Date?
    private let speechService = SpeechService.shared
    private let notificationService = NotificationService.shared

    init() {
        self.settings = ClockSettings.load()
        startTimer()
        checkNotificationAuthorization()
    }

    deinit {
        timer?.invalidate()
    }

    private func startTimer() {
        // Update time every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
        timer?.tolerance = 0.1
    }

    private func updateTime() {
        currentTime = Date()
        checkForAnnouncement()
    }

    private func checkForAnnouncement() {
        guard settings.isAnnouncementEnabled else { return }

        let intervalSeconds = settings.intervalInSeconds

        // Check if current time aligns with the interval
        if isTimeAlignedWithInterval(currentTime, intervalSeconds: intervalSeconds) {
            // Prevent multiple announcements for the same second
            if let lastAnnouncement = lastAnnouncementTime,
               Calendar.current.isDate(lastAnnouncement, equalTo: currentTime, toGranularity: .second) {
                return
            }

            lastAnnouncementTime = currentTime
            speakCurrentTime()
        }
    }

    private func isTimeAlignedWithInterval(_ date: Date, intervalSeconds: TimeInterval) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)

        guard let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return false
        }

        let totalSeconds = hour * 3600 + minute * 60 + second
        let intervalInt = Int(intervalSeconds)

        return totalSeconds % intervalInt == 0
    }

    func speakCurrentTime() {
        speechService.speakTime(currentTime)
    }

    func updateIntervalValue(_ value: Int) {
        settings.intervalValue = value
    }

    func updateTimeUnit(_ unit: TimeUnit) {
        settings.timeUnit = unit
        // Reset to first available interval for the new unit
        if !unit.availableIntervals.contains(settings.intervalValue) {
            settings.intervalValue = unit.availableIntervals.first ?? 1
        }
    }

    func toggleAnalogClock() {
        settings.showAnalogClock.toggle()
    }

    func toggleAnnouncement() {
        settings.isAnnouncementEnabled.toggle()
    }

    // MARK: - Notifications

    func requestNotificationPermission() {
        notificationService.requestAuthorization { [weak self] granted in
            self?.notificationsAuthorized = granted
            if granted {
                self?.rescheduleNotifications()
            }
        }
    }

    private func checkNotificationAuthorization() {
        notificationService.checkAuthorizationStatus { [weak self] authorized in
            self?.notificationsAuthorized = authorized
            if authorized {
                self?.rescheduleNotifications()
            }
        }
    }

    private func rescheduleNotifications() {
        notificationService.scheduleTimeAnnouncements(
            intervalSeconds: settings.intervalInSeconds,
            enabled: settings.isAnnouncementEnabled && notificationsAuthorized
        )
    }
}
