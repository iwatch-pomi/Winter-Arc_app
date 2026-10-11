import Foundation
import UserNotifications

enum NotificationManager {
    private static let dailyReminderID = "daily-reminder"
    private static let focusEndID = "focus-end"

    private static var center: UNUserNotificationCenter { .current() }

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleDailyReminder(minutesOfDay: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
        let content = UNMutableNotificationContent()
        content.title = "Winter Arc"
        content.body = "今日の振り返りと習慣チェックをしましょう。小さな積み重ねが、大きな変化を生む。"
        content.sound = .default
        var components = DateComponents()
        components.hour = minutesOfDay / 60
        components.minute = minutesOfDay % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger))
    }

    static func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    static func scheduleFocusEnd(at date: Date) {
        let interval = date.timeIntervalSinceNow
        guard interval > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = "集中モード完了"
        content.body = "おつかれさまでした！少し休憩しましょう。"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: focusEndID, content: content, trigger: trigger))
    }

    static func cancelFocusEnd() {
        center.removePendingNotificationRequests(withIdentifiers: [focusEndID])
    }
}
