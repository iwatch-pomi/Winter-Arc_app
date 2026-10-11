import Foundation
import SwiftData

@Model
final class Habit {
    var name: String = ""
    var detail: String = ""
    var icon: String = "flame.fill"
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]? = []

    init(name: String, detail: String = "", icon: String = "flame.fill", sortOrder: Int = 0) {
        self.name = name
        self.detail = detail
        self.icon = icon
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var doneDays: Set<Date> {
        Set((logs ?? []).map { $0.day.startOfDay })
    }

    func isDone(on day: Date) -> Bool {
        (logs ?? []).contains { $0.day.isSameDay(as: day) }
    }

    func log(on day: Date) -> HabitLog? {
        (logs ?? []).first { $0.day.isSameDay(as: day) }
    }

    /// 今日（未達成なら昨日）からさかのぼった連続達成日数
    var currentStreak: Int {
        let days = doneDays
        var cursor = Date().startOfDay
        if !days.contains(cursor) { cursor = cursor.adding(days: -1) }
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = cursor.adding(days: -1)
        }
        return count
    }

    var bestStreak: Int {
        let sorted = doneDays.sorted()
        var best = 0
        var run = 0
        var previous: Date?
        for day in sorted {
            if let previous, previous.adding(days: 1).isSameDay(as: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}

@Model
final class HabitLog {
    var day: Date = Date()
    var habit: Habit?

    init(day: Date) {
        self.day = day.startOfDay
    }
}

struct HabitPreset: Identifiable, Hashable {
    let name: String
    let icon: String
    var id: String { name }

    static let all: [HabitPreset] = [
        HabitPreset(name: "早起き（6:30）", icon: "sunrise.fill"),
        HabitPreset(name: "運動（30分以上）", icon: "figure.run"),
        HabitPreset(name: "読書（30分以上）", icon: "book.fill"),
        HabitPreset(name: "SNS制限（1時間以内）", icon: "iphone.slash"),
        HabitPreset(name: "就寝（23:00まで）", icon: "moon.zzz.fill"),
        HabitPreset(name: "水を2L飲む", icon: "drop.fill"),
        HabitPreset(name: "瞑想（5分）", icon: "leaf.fill"),
    ]

    static let defaultSelection: Set<String> = Set(all.prefix(5).map(\.name))

    static let icons = [
        "flame.fill", "sunrise.fill", "figure.run", "dumbbell.fill", "book.fill",
        "books.vertical.fill", "pencil", "iphone.slash", "moon.zzz.fill", "bed.double.fill",
        "drop.fill", "leaf.fill", "heart.fill", "fork.knife", "cup.and.saucer.fill",
        "brain.head.profile", "music.note", "globe", "dollarsign.circle.fill", "star.fill",
    ]
}
