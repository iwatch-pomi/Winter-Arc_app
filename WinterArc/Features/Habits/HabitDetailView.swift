import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let habit: Habit

    @State private var month = Date()
    @State private var showEditor = false
    @State private var confirmDelete = false

    private var monthDays: [Date] {
        guard let interval = Calendar.app.dateInterval(of: .month, for: month) else { return [] }
        var days: [Date] = []
        var cursor = interval.start
        while cursor < interval.end {
            days.append(cursor)
            cursor = cursor.adding(days: 1)
        }
        return days
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                stats
                calendar
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Text("この習慣を削除").foregroundStyle(.red)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(16)
        }
        .winterScreen()
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("編集") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            HabitEditorView(habit: habit, nextSortOrder: habit.sortOrder)
        }
        .confirmationDialog("「\(habit.name)」を削除しますか？記録もすべて削除されます。", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                dismiss()
                // 画面を閉じてから削除する（削除済みデータを表示しないため）
                let target = habit
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    context.delete(target)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: habit.icon)
                .font(.largeTitle)
                .frame(width: 80, height: 80)
                .background(Circle().fill(Theme.elevated))
            Text(habit.name)
                .font(.title3.weight(.semibold))
            if !habit.detail.isEmpty {
                Text(habit.detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statTile("現在の連続", "\(habit.currentStreak)", "日")
            statTile("最長連続", "\(habit.bestStreak)", "日")
            statTile("累計", "\(habit.doneDays.count)", "日")
        }
    }

    private func statTile(_ title: String, _ value: String, _ suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
            StatValue(value: value, suffix: suffix, size: 24)
        }
        .card(padding: 12)
    }

    private var calendar: some View {
        let leading = monthDays.first?.weekdayIndex ?? 0
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return VStack(spacing: 14) {
            HStack {
                Button {
                    month = month.adding(.month, -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(month.text("yyyy年M月"))
                    .font(.headline)
                Spacer()
                Button {
                    month = month.adding(.month, 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Weekday.symbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
                ForEach(0..<leading, id: \.self) { _ in
                    Color.clear.frame(height: 34)
                }
                ForEach(monthDays, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .card()
    }

    private func dayCell(_ day: Date) -> some View {
        let done = habit.isDone(on: day)
        let future = day.isFutureDay
        return Button {
            HabitToggler.toggle(habit, on: day, in: context)
        } label: {
            Text("\(Calendar.app.component(.day, from: day))")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(done ? Color.black : (future ? Theme.tertiaryText : Color.white))
                .frame(width: 34, height: 34)
                .background(Circle().fill(done ? Color.white : Color.clear))
                .overlay(Circle().stroke(day.isToday && !done ? Color.white : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(future)
    }
}
