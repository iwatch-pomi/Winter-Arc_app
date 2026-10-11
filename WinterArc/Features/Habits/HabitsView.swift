import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Habit.sortOrder), SortDescriptor(\Habit.createdAt)])
    private var habits: [Habit]

    @State private var path = NavigationPath()
    @State private var showNewHabit = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 14) {
                    summary
                    if habits.isEmpty {
                        emptyState
                    } else {
                        ForEach(habits) { habit in
                            row(habit)
                        }
                    }
                    Button {
                        showNewHabit = true
                    } label: {
                        Label("習慣を追加", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .winterScreen()
            .navigationTitle("習慣")
            .navigationDestination(for: Habit.self) { habit in
                HabitDetailView(habit: habit)
            }
            .sheet(isPresented: $showNewHabit) {
                HabitEditorView(habit: nil, nextSortOrder: (habits.map(\.sortOrder).max() ?? -1) + 1)
            }
        }
    }

    private var summary: some View {
        let stats = HabitStats.week(habits: habits)
        return VStack(alignment: .leading, spacing: 12) {
            Text("今週の習慣達成率")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            HStack(alignment: .firstTextBaseline) {
                StatValue(value: "\(Int((stats.rate * 100).rounded()))", suffix: "%", size: 40)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.perfectDays)/7")
                        .font(Theme.number(17))
                    Text("全達成日")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            ProgressBar(value: stats.rate, height: 8)
        }
        .card()
    }

    private func row(_ habit: Habit) -> some View {
        HStack(spacing: 14) {
            Image(systemName: habit.icon)
                .font(.title3)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Theme.elevated))
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(habit.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .layoutPriority(1)
                    if habit.currentStreak > 1 {
                        Label("\(habit.currentStreak)日連続", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                HabitWeekCircles(habit: habit) { day in
                    HabitToggler.toggle(habit, on: day, in: context)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.tertiaryText)
        }
        .card(padding: 14)
        .contentShape(Rectangle())
        .onTapGesture { path.append(habit) }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame")
                .font(.system(size: 36))
                .foregroundStyle(Theme.tertiaryText)
            Text("毎日続けたい習慣を追加しましょう")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

enum HabitToggler {
    static func toggle(_ habit: Habit, on day: Date, in context: ModelContext) {
        guard !day.isFutureDay else { return }
        if let log = habit.log(on: day) {
            habit.logs?.removeAll { $0.persistentModelID == log.persistentModelID }
            context.delete(log)
        } else {
            let log = HabitLog(day: day)
            context.insert(log)
            log.habit = habit
        }
        try? context.save()
    }
}
