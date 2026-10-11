#if DEBUG
import Foundation
import SwiftData

/// 開発用：起動引数 `-seedSampleData YES` でサンプルデータを入れる
/// （`-initialTab tasks` などで最初に開くタブも指定できる）
enum SampleData {
    static var isRequested: Bool { UserDefaults.standard.bool(forKey: "seedSampleData") }

    static var initialTab: AppTab? {
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "home": .home
        case "tasks": .tasks
        case "habits": .habits
        case "records": .records
        case "settings": .settings
        default: nil
        }
    }

    static func seedIfNeeded(_ context: ModelContext) {
        guard isRequested else { return }
        let count = (try? context.fetchCount(FetchDescriptor<TaskItem>())) ?? 0
        guard count == 0 else { return }

        let today = Date().startOfDay
        let routine: [(Int, String, TaskCategory)] = [
            (390, "起床・ストレッチ", .life),
            (420, "朝食・読書（30分）", .life),
            (480, "英単語（1時間）", .study),
            (600, "授業・講義", .study),
            (780, "昼食・休憩", .life),
            (840, "資格勉強（2時間）", .study),
            (1020, "ジム（筋トレ）", .workout),
            (1200, "振り返り・日記", .other),
            (1350, "就寝", .life),
        ]
        for offset in -6...0 {
            let day = today.adding(days: offset)
            for (index, item) in routine.enumerated() {
                let task = TaskItem(title: item.1, day: day, startMinutes: item.0, durationMinutes: 60, category: item.2)
                if offset < 0 ? (index + offset) % 4 != 0 : index < 3 {
                    task.isDone = true
                    task.completedAt = day
                }
                context.insert(task)
            }
        }

        for (index, preset) in HabitPreset.all.prefix(5).enumerated() {
            let habit = Habit(name: preset.name, icon: preset.icon, sortOrder: index)
            context.insert(habit)
            for offset in -20...0 where (offset + index) % 5 != 0 || offset > -3 {
                let log = HabitLog(day: today.adding(days: offset))
                context.insert(log)
                log.habit = habit
            }
        }

        for offset in -60...0 {
            let day = today.adding(days: offset).addingTimeInterval(20 * 3600)
            context.insert(LogEntry(kind: .study, value: Double(2 + abs(offset * 7) % 5) * 0.75, date: day))
            if offset % 2 == 0 {
                context.insert(LogEntry(kind: .weight, value: 68.0 + Double(offset + 60) * -0.03 + Double(offset % 3) * 0.2, date: day))
            }
            if offset % 9 == 0 {
                context.insert(LogEntry(kind: .book, value: 1, date: day))
            }
            context.insert(LogEntry(kind: .exercise, value: Double(30 + abs(offset * 13) % 40), date: day))
            context.insert(LogEntry(kind: .sleep, value: 6.5 + Double((offset + 60) % 3) * 0.5, date: day))
        }

        context.insert(Goal(title: "大学に合格する"))
        context.insert(Goal(title: "英語を話せるようになる"))
        context.insert(Goal(title: "体を鍛えて健康になる", isLongTerm: false))
        try? context.save()
    }
}
#endif
