import Foundation

enum SettingsKey {
    static let onboardingCompleted = "onboardingCompleted"
    static let seasonStart = "seasonStart"
    static let seasonEnd = "seasonEnd"
    static let userName = "userName"
    static let targetWeight = "targetWeight"
    static let reminderEnabled = "reminderEnabled"
    static let reminderMinutes = "reminderMinutes"
    static let focusMinutes = "focusMinutes"
}

/// Winter Arc の「挑戦期間」
struct Season {
    static let defaultLength = 90

    let start: Date
    let end: Date

    init(start: Double, end: Double) {
        let today = Date().startOfDay
        let s = start == 0 ? today : Date(timeIntervalSinceReferenceDate: start).startOfDay
        let e = end == 0 ? s.adding(days: Season.defaultLength - 1) : Date(timeIntervalSinceReferenceDate: end).startOfDay
        self.start = s
        self.end = max(e, s)
    }

    var totalDays: Int { start.days(until: end) + 1 }

    /// 今日が何日目か（開始前は0、終了後は totalDays）
    func dayNumber(on date: Date = Date()) -> Int {
        min(max(start.days(until: date) + 1, 0), totalDays)
    }

    func progress(on date: Date = Date()) -> Double {
        Double(dayNumber(on: date)) / Double(totalDays)
    }

    func remainingDays(on date: Date = Date()) -> Int {
        max(totalDays - dayNumber(on: date), 0)
    }

    var hasNotStarted: Bool { start > Date().startOfDay }
}
