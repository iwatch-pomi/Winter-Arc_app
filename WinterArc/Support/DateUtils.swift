import Foundation

extension Calendar {
    /// 月曜はじまりの日本語カレンダー
    static let app: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.firstWeekday = 2
        return calendar
    }()
}

extension Date {
    var startOfDay: Date { Calendar.app.startOfDay(for: self) }

    func adding(days: Int) -> Date {
        Calendar.app.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(_ component: Calendar.Component, _ value: Int) -> Date {
        Calendar.app.date(byAdding: component, value: value, to: self) ?? self
    }

    var startOfWeek: Date {
        Calendar.app.dateInterval(of: .weekOfYear, for: self)?.start ?? startOfDay
    }

    /// その週の月曜〜日曜
    var weekDays: [Date] {
        let start = startOfWeek
        return (0..<7).map { start.adding(days: $0) }
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.app.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool { Calendar.app.isDateInToday(self) }

    var isFutureDay: Bool { startOfDay > Date().startOfDay }

    /// 月曜=0 ... 日曜=6
    var weekdayIndex: Int {
        (Calendar.app.component(.weekday, from: self) + 5) % 7
    }

    func days(until other: Date) -> Int {
        Calendar.app.dateComponents([.day], from: startOfDay, to: other.startOfDay).day ?? 0
    }

    func text(_ format: String, english: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: english ? "en_US_POSIX" : "ja_JP")
        formatter.calendar = Calendar.app
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

enum Weekday {
    static let symbols = ["月", "火", "水", "木", "金", "土", "日"]
}

enum TimeText {
    /// 390 → "6:30"
    static func clock(_ minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    /// 90 → "1時間30分"
    static func duration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        switch (h, m) {
        case (0, _): return "\(m)分"
        case (_, 0): return "\(h)時間"
        default: return "\(h)時間\(m)分"
        }
    }

    /// 1.0 → "1", 32.5 → "32.5"
    static func number(_ value: Double, digits: Int = 1) -> String {
        let rounded = (value * pow(10, Double(digits))).rounded() / pow(10, Double(digits))
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.\(digits)f", rounded)
    }

    static func signed(_ value: Double, digits: Int = 1) -> String {
        let text = number(abs(value), digits: digits)
        if value > 0 { return "+" + text }
        if value < 0 { return "-" + text }
        return "±0"
    }
}
