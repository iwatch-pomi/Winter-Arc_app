import SwiftUI
import SwiftData

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let habit: Habit?
    let nextSortOrder: Int

    @State private var name: String
    @State private var detail: String
    @State private var icon: String

    init(habit: Habit?, nextSortOrder: Int) {
        self.habit = habit
        self.nextSortOrder = nextSortOrder
        _name = State(initialValue: habit?.name ?? "")
        _detail = State(initialValue: habit?.detail ?? "")
        _icon = State(initialValue: habit?.icon ?? "flame.fill")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("習慣") {
                    TextField("名前（例：早起き 6:30）", text: $name)
                    TextField("メモ（任意）", text: $detail, axis: .vertical)
                }

                if habit == nil {
                    Section("おすすめ") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(HabitPreset.all) { preset in
                                    Button {
                                        name = preset.name
                                        icon = preset.icon
                                    } label: {
                                        Label(preset.name, systemImage: preset.icon)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Capsule().fill(Theme.elevated))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(HabitPreset.icons, id: \.self) { symbol in
                            Button {
                                icon = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .foregroundStyle(icon == symbol ? Color.black : Color.white)
                                    .frame(width: 46, height: 46)
                                    .background(Circle().fill(icon == symbol ? Color.white : Theme.elevated))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.05))
            .navigationTitle(habit == nil ? "習慣を追加" : "習慣を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let habit {
            habit.name = trimmed
            habit.detail = detail
            habit.icon = icon
        } else {
            context.insert(Habit(name: trimmed, detail: detail, icon: icon, sortOrder: nextSortOrder))
        }
        dismiss()
    }
}
