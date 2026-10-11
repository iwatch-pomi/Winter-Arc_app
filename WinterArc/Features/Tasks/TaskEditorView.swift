import SwiftUI
import SwiftData

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let task: TaskItem?

    @State private var title: String
    @State private var day: Date
    @State private var hour: Int
    @State private var minute: Int
    @State private var duration: Int
    @State private var category: TaskCategory
    @State private var note: String

    private static let durations = [15, 30, 45, 60, 90, 120, 180, 240]

    init(task: TaskItem?, defaultDate: Date) {
        self.task = task
        let start = task?.startMinutes ?? Self.suggestedStart(for: defaultDate)
        _title = State(initialValue: task?.title ?? "")
        _day = State(initialValue: task?.day ?? defaultDate)
        _hour = State(initialValue: start / 60)
        _minute = State(initialValue: (start % 60) / 15 * 15)
        _duration = State(initialValue: task?.durationMinutes ?? 30)
        _category = State(initialValue: task?.category ?? .study)
        _note = State(initialValue: task?.note ?? "")
    }

    /// 今日なら次の15分区切り、それ以外は 9:00
    private static func suggestedStart(for date: Date) -> Int {
        guard date.isToday else { return 9 * 60 }
        let now = Calendar.app.dateComponents([.hour, .minute], from: Date())
        let minutes = (now.hour ?? 9) * 60 + (now.minute ?? 0)
        return min((minutes / 15 + 1) * 15, 23 * 60 + 45)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タスク名（例：英単語 1時間）", text: $title)
                }

                Section("日時") {
                    DatePicker("日付", selection: $day, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    HStack {
                        Text("開始時刻")
                        Spacer()
                        Picker("時", selection: $hour) {
                            ForEach(0..<24, id: \.self) { Text("\($0)時").tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        Picker("分", selection: $minute) {
                            ForEach([0, 15, 30, 45], id: \.self) { Text(String(format: "%02d分", $0)).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    Picker("所要時間", selection: $duration) {
                        ForEach(Self.durations, id: \.self) { Text(TimeText.duration($0)).tag($0) }
                    }
                }

                Section("カテゴリ") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(TaskCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("メモ") {
                    TextField("メモ（任意）", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let task {
                    Section {
                        Button("このタスクを削除", role: .destructive) {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                context.delete(task)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.05))
            .navigationTitle(task == nil ? "新しいタスク" : "タスクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let start = hour * 60 + minute
        if let task {
            task.title = trimmed
            task.day = day.startOfDay
            task.startMinutes = start
            task.durationMinutes = duration
            task.category = category
            task.note = note
        } else {
            context.insert(TaskItem(
                title: trimmed,
                day: day,
                startMinutes: start,
                durationMinutes: duration,
                category: category,
                note: note
            ))
        }
        dismiss()
    }
}
