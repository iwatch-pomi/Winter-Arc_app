import Foundation

enum RecordPeriod: String, CaseIterable, Identifiable {
    case week = "週間"
    case month = "月間"
    case year = "年間"

    var id: String { rawValue }

    private var component: Calendar.Component {
        switch self {
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }

    var comparisonLabel: String {
        switch self {
        case .week: "前週比"
        case .month: "前月比"
        case .year: "前年比"
        }
    }

    func interval(containing date: Date) -> DateInterval {
        Calendar.app.dateInterval(of: component, for: date)
            ?? DateInterval(start: date.startOfDay, duration: 86_400)
    }

    func shift(_ date: Date, by value: Int) -> Date {
        date.adding(component, value)
    }

    func title(for interval: DateInterval) -> String {
        let last = interval.end.addingTimeInterval(-1)
        switch self {
        case .week:
            return "\(interval.start.text("M/d"))〜\(last.text("M/d"))"
        case .month:
            return interval.start.text("yyyy年M月")
        case .year:
            return interval.start.text("yyyy年")
        }
    }

    /// グラフの棒ひとつぶん
    struct Bucket: Identifiable {
        let label: String
        let interval: DateInterval
        var id: String { label }
    }

    func buckets(for interval: DateInterval) -> [Bucket] {
        var result: [Bucket] = []
        var cursor = interval.start
        var index = 0
        while cursor < interval.end {
            let next: Date
            let label: String
            switch self {
            case .week:
                next = cursor.adding(days: 1)
                label = Weekday.symbols[index % 7]
            case .month:
                next = cursor.adding(days: 1)
                label = "\(Calendar.app.component(.day, from: cursor))"
            case .year:
                next = cursor.adding(.month, 1)
                label = "\(Calendar.app.component(.month, from: cursor))月"
            }
            result.append(Bucket(label: label, interval: DateInterval(start: cursor, end: next)))
            cursor = next
            index += 1
        }
        return result
    }

    func axisLabels(for buckets: [Bucket]) -> [String] {
        switch self {
        case .week:
            return buckets.map(\.label)
        case .month:
            return buckets.map(\.label).filter { ["1", "8", "15", "22", "29"].contains($0) }
        case .year:
            return buckets.enumerated().filter { $0.offset % 3 == 0 }.map(\.element.label)
        }
    }
}

struct ChartPoint: Identifiable {
    let label: String
    let value: Double
    let isHighlighted: Bool
    var id: String { label }
}

extension Array where Element == LogEntry {
    func entries(_ kind: LogKind, in interval: DateInterval) -> [LogEntry] {
        filter { $0.kind == kind && interval.contains($0.date) && $0.date < interval.end }
            .sorted { $0.date < $1.date }
    }

    func total(_ kind: LogKind, in interval: DateInterval) -> Double {
        kind.aggregate(entries(kind, in: interval).map(\.value))
    }

    func chartPoints(_ kind: LogKind, period: RecordPeriod, interval: DateInterval) -> [ChartPoint] {
        let relevant = entries(kind, in: interval)
        let now = Date()
        return period.buckets(for: interval).map { bucket in
            let values = relevant
                .filter { bucket.interval.contains($0.date) && $0.date < bucket.interval.end }
                .map(\.value)
            let current = bucket.interval.contains(now) && now < bucket.interval.end
            return ChartPoint(label: bucket.label, value: kind.aggregate(values), isHighlighted: current)
        }
    }
}

extension Array where Element == TaskItem {
    func tasks(in interval: DateInterval) -> [TaskItem] {
        filter { $0.day >= interval.start && $0.day < interval.end }
    }
}

enum HabitStats {
    /// 週の達成率（今日までの日のみ対象）と、全習慣達成できた日数
    static func week(habits: [Habit], containing date: Date = Date()) -> (rate: Double, perfectDays: Int, elapsedDays: Int) {
        let days = date.weekDays.filter { !$0.isFutureDay }
        guard !habits.isEmpty, !days.isEmpty else { return (0, 0, days.count) }
        var checks = 0
        var perfect = 0
        for day in days {
            let done = habits.filter { $0.isDone(on: day) }.count
            checks += done
            if done == habits.count { perfect += 1 }
        }
        let rate = Double(checks) / Double(habits.count * days.count)
        return (rate, perfect, days.count)
    }
}
