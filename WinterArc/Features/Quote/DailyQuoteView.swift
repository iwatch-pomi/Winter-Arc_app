import SwiftUI
import SwiftData

struct DailyQuoteView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(sort: \LogEntry.date) private var logs: [LogEntry]

    private let quote = Quotes.of()

    private var highlights: [String] {
        let today = DateInterval(start: Date().startOfDay, end: Date().startOfDay.adding(days: 1))
        var items: [String] = []

        let todayTasks = tasks.filter { $0.day.isToday }
        let done = todayTasks.filter(\.isDone).count
        if done > 0 {
            items.append("タスクを\(done)つ完了しました！")
        }
        if !todayTasks.isEmpty && done == todayTasks.count {
            items.append("今日のタスクをすべてやり切りました。")
        }

        let doneHabits = habits.filter { $0.isDone(on: Date()) }.count
        if doneHabits > 0 {
            items.append("習慣を\(doneHabits)/\(habits.count)達成しました。")
        }
        if let best = habits.max(by: { $0.currentStreak < $1.currentStreak }), best.currentStreak >= 3 {
            items.append("「\(best.name)」が\(best.currentStreak)日連続です。")
        }

        let study = logs.total(.study, in: today)
        if study > 0 {
            let pastDays = (1...30).map { offset -> Double in
                let start = Date().startOfDay.adding(days: -offset)
                return logs.total(.study, in: DateInterval(start: start, end: start.adding(days: 1)))
            }
            if study > (pastDays.max() ?? 0) {
                items.append("勉強時間が過去30日で最高を記録しました！")
            } else {
                items.append("今日の勉強時間は\(TimeText.number(study))時間です。")
            }
        }

        let sleep = logs.entries(.sleep, in: today).last
        if let sleep {
            items.append("睡眠時間は\(TimeText.number(sleep.value))時間でした。\(sleep.value >= 7 ? "良いペースです。" : "今夜は早めに休みましょう。")")
        }

        if items.isEmpty {
            items.append("まずは1つ、タスクを完了させましょう。")
            items.append("小さな積み重ねが、大きな変化を生む。")
        }
        return items
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text(Date().text("M月d日（E）"))
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)

                    VStack(alignment: .center, spacing: 18) {
                        Text("「\(quote.text)」")
                            .font(.system(size: 21, weight: .medium, design: .serif))
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                        Text("— \(quote.author)")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 12)

                    Divider().overlay(Theme.stroke)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("今日のハイライト")
                            .font(.headline)
                        ForEach(highlights, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("・")
                                Text(item)
                            }
                            .font(.subheadline)
                        }
                    }

                    MountainArtView()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .padding(24)
            }
            .winterScreen()
            .navigationTitle("今日の名言")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct TodayScheduleView: View {
    @Query(sort: \TaskItem.startMinutes) private var tasks: [TaskItem]

    private var todayTasks: [TaskItem] { tasks.filter { $0.day.isToday } }

    var body: some View {
        List {
            Section {
                if todayTasks.isEmpty {
                    Text("今日の予定はまだありません")
                        .foregroundStyle(Theme.secondaryText)
                }
                ForEach(todayTasks) { task in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(task.isDone ? Theme.tertiaryText : Color.white)
                            .frame(width: 6, height: 6)
                        Text(task.timeText)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 46, alignment: .leading)
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(task.isDone ? Theme.secondaryText : Color.white)
                        Spacer()
                        Button {
                            withAnimation { task.toggle() }
                        } label: {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(task.isDone ? Color.white : Theme.secondaryText)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text(Date().text("M月d日（E）"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .textCase(nil)
            }
            .listRowBackground(Theme.background)
            .listRowSeparatorTint(Theme.stroke)
        }
        .listStyle(.plain)
        .winterScreen()
        .navigationTitle("今日のスケジュール")
        .navigationBarTitleDisplayMode(.inline)
    }
}
