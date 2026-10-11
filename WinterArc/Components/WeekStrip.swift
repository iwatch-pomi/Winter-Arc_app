import SwiftUI

/// 月〜日の横並びカレンダー
struct WeekStrip: View {
    @Binding var selection: Date
    /// その日にタスクなどがあるかどうか（ドット表示）
    var hasItems: (Date) -> Bool = { _ in false }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(selection.weekDays, id: \.self) { day in
                let selected = day.isSameDay(as: selection)
                Button {
                    selection = day
                } label: {
                    VStack(spacing: 6) {
                        Text(Weekday.symbols[day.weekdayIndex])
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText)
                        Text("\(Calendar.app.component(.day, from: day))")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(selected ? Color.black : Color.white)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle().fill(selected ? Color.white : Color.clear)
                            )
                            .overlay(
                                Circle().stroke(day.isToday && !selected ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                        Circle()
                            .fill(hasItems(day) ? Theme.secondaryText : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 「すべて / 勉強 / 筋トレ ...」の絞り込みチップ
struct CategoryChips: View {
    @Binding var selection: TaskCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "すべて", isSelected: selection == nil) { selection = nil }
                ForEach(TaskCategory.allCases) { category in
                    chip(title: category.rawValue, isSelected: selection == category) { selection = category }
                }
            }
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Color.white : Theme.elevated))
        }
        .buttonStyle(.plain)
    }
}

/// 習慣の「月火水木金土日」丸ボタン
struct HabitWeekCircles: View {
    let habit: Habit
    var week: Date = Date()
    let onToggle: (Date) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(week.weekDays, id: \.self) { day in
                let done = habit.isDone(on: day)
                let future = day.isFutureDay
                Button {
                    onToggle(day)
                } label: {
                    Text(Weekday.symbols[day.weekdayIndex])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(done ? Color.black : (future ? Theme.tertiaryText : Color.white))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(done ? Color.white : Color.clear))
                        .overlay(
                            Circle().stroke(
                                done ? Color.clear : (day.isToday ? Color.white : Color.white.opacity(future ? 0.15 : 0.35)),
                                lineWidth: day.isToday ? 1.5 : 1
                            )
                        )
                }
                .buttonStyle(.plain)
                .disabled(future)
            }
        }
    }
}
