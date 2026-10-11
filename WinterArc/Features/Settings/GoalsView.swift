import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    @State private var newTitle = ""
    @State private var newIsLongTerm = true

    var body: some View {
        List {
            Section {
                TextField("新しい目標（例：TOEIC 800点）", text: $newTitle)
                    .onSubmit(add)
                Picker("種類", selection: $newIsLongTerm) {
                    Text("長期目標").tag(true)
                    Text("短期目標").tag(false)
                }
                .pickerStyle(.segmented)
                Button("追加", action: add)
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            } footer: {
                Text("やりたいこと・なりたい自分を明確に。長期目標と、そこへ向かう短期目標を設定しましょう。")
            }
            .listRowBackground(Theme.card)

            goalSection("長期目標", goals.filter(\.isLongTerm))
            goalSection("短期目標", goals.filter { !$0.isLongTerm })
        }
        .winterScreen()
        .navigationTitle("目標")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func goalSection(_ title: String, _ items: [Goal]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { goal in
                    Button {
                        withAnimation { goal.isAchieved.toggle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: goal.isAchieved ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                            Text(goal.title)
                                .strikethrough(goal.isAchieved)
                                .foregroundStyle(goal.isAchieved ? Theme.secondaryText : Color.white)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(items[index]) }
                }
            }
            .listRowBackground(Theme.card)
        }
    }

    private func add() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        context.insert(Goal(title: title, isLongTerm: newIsLongTerm))
        newTitle = ""
    }
}
