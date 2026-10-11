import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\TaskItem.startMinutes), SortDescriptor(\TaskItem.createdAt)])
    private var allTasks: [TaskItem]

    @State private var selectedDate = Date().startOfDay
    @State private var filter: TaskCategory?
    @State private var showNewTask = false
    @State private var editingTask: TaskItem?

    private var dayTasks: [TaskItem] {
        allTasks.filter { $0.day.isSameDay(as: selectedDate) }
    }

    private var visibleTasks: [TaskItem] {
        guard let filter else { return dayTasks }
        return dayTasks.filter { $0.category == filter }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    calendarHeader
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    if visibleTasks.isEmpty {
                        emptyState
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(visibleTasks) { task in
                            TaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                                .listRowBackground(Theme.background)
                                .listRowSeparatorTint(Theme.stroke)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(task)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        withAnimation { task.toggle() }
                                    } label: {
                                        Label(task.isDone ? "未完了" : "完了", systemImage: "checkmark")
                                    }
                                    .tint(.gray)
                                }
                        }
                    }
                } header: {
                    summaryHeader
                }
            }
            .listStyle(.plain)
            .winterScreen()
            .navigationTitle("タスク")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { menu }
            }
            .overlay(alignment: .bottomTrailing) { addButton }
            .sheet(isPresented: $showNewTask) {
                TaskEditorView(task: nil, defaultDate: selectedDate)
            }
            .sheet(item: $editingTask) { task in
                TaskEditorView(task: task, defaultDate: task.day)
            }
        }
    }

    // MARK: - Parts

    private var calendarHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(selectedDate.text("yyyy年M月"))
                    .font(.headline)
                Spacer()
                Button {
                    selectedDate = selectedDate.adding(days: -7)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button("今日") {
                    selectedDate = Date().startOfDay
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 6)
                Button {
                    selectedDate = selectedDate.adding(days: 7)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.white)

            WeekStrip(selection: $selectedDate) { day in
                allTasks.contains { $0.day.isSameDay(as: day) }
            }

            CategoryChips(selection: $filter)
        }
    }

    private var summaryHeader: some View {
        let done = dayTasks.filter(\.isDone).count
        return HStack {
            Text(selectedDate.text("M月d日（E）"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Text("\(done)/\(dayTasks.count) 完了")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checklist")
                .font(.system(size: 36))
                .foregroundStyle(Theme.tertiaryText)
            Text(filter == nil ? "この日のタスクはまだありません" : "このカテゴリのタスクはありません")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            if filter == nil {
                Button("前日のタスクをコピー") { copyPreviousDay() }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: 240)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var menu: some View {
        Menu {
            Button {
                copyPreviousDay()
            } label: {
                Label("前日のタスクをコピー", systemImage: "doc.on.doc")
            }
            Button {
                for task in dayTasks where !task.isDone { task.toggle() }
            } label: {
                Label("すべて完了にする", systemImage: "checkmark.circle")
            }
            Button(role: .destructive) {
                for task in dayTasks where task.isDone { delete(task) }
            } label: {
                Label("完了済みを削除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.white)
        }
    }

    private var addButton: some View {
        Button {
            showNewTask = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
        }
        .padding(20)
        .accessibilityLabel("タスクを追加")
    }

    // MARK: - Actions

    private func delete(_ task: TaskItem) {
        withAnimation { context.delete(task) }
    }

    private func copyPreviousDay() {
        let previous = selectedDate.adding(days: -1)
        let source = allTasks.filter { $0.day.isSameDay(as: previous) }
        let existingTitles = Set(dayTasks.map { "\($0.startMinutes)-\($0.title)" })
        withAnimation {
            for task in source where !existingTitles.contains("\(task.startMinutes)-\(task.title)") {
                context.insert(TaskItem(
                    title: task.title,
                    day: selectedDate,
                    startMinutes: task.startMinutes,
                    durationMinutes: task.durationMinutes,
                    category: task.category,
                    note: task.note
                ))
            }
        }
    }
}

struct TaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.snappy) { task.toggle() }
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? Color.white : Theme.secondaryText)
            }
            .buttonStyle(.borderless)

            Text(task.timeText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 46, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.isDone, color: Theme.secondaryText)
                    .foregroundStyle(task.isDone ? Theme.secondaryText : Color.white)
                HStack(spacing: 6) {
                    Label(task.category.rawValue, systemImage: task.category.icon)
                    Text("・\(TimeText.duration(task.durationMinutes))")
                }
                .font(.caption2)
                .foregroundStyle(Theme.tertiaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }
}
