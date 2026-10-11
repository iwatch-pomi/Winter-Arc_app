import SwiftUI
import SwiftData

struct LogEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State var kind: LogKind
    @State private var valueText: String
    @State private var date = Date()
    @State private var note = ""
    @FocusState private var focused: Bool

    init(kind: LogKind) {
        _kind = State(initialValue: kind)
        _valueText = State(initialValue: kind.defaultValue.map { TimeText.number($0) } ?? "")
    }

    private var value: Double? {
        Double(valueText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("種類", selection: $kind) {
                        ForEach(LogKind.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                }
                Section("値") {
                    HStack {
                        TextField("0", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(Theme.number(28))
                            .focused($focused)
                        Text(kind.inputUnit)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    if kind == .study {
                        HStack {
                            ForEach([0.5, 1, 1.5, 2], id: \.self) { hours in
                                Button("\(TimeText.number(hours))h") { valueText = TimeText.number(hours) }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                Section {
                    DatePicker("日時", selection: $date)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    TextField("メモ（任意）", text: $note)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.05))
            .navigationTitle("\(kind.title)を記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled((value ?? 0) <= 0)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let value, value > 0 else { return }
        context.insert(LogEntry(kind: kind, value: value, date: date, note: note))
        dismiss()
    }
}

struct LogHistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LogEntry.date, order: .reverse) private var logs: [LogEntry]
    @State private var filter: LogKind?

    private var filtered: [LogEntry] {
        guard let filter else { return logs }
        return logs.filter { $0.kind == filter }
    }

    var body: some View {
        List {
            Section {
                Picker("種類", selection: $filter) {
                    Text("すべて").tag(LogKind?.none)
                    ForEach(LogKind.allCases) { Text($0.title).tag(LogKind?.some($0)) }
                }
            }
            .listRowBackground(Theme.card)

            Section {
                if filtered.isEmpty {
                    Text("記録はまだありません")
                        .foregroundStyle(Theme.secondaryText)
                }
                ForEach(filtered) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.kind.icon)
                            .frame(width: 28)
                            .foregroundStyle(Theme.secondaryText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.kind.title)
                                .font(.subheadline)
                            Text(entry.date.text("M/d（E）H:mm"))
                                .font(.caption2)
                                .foregroundStyle(Theme.tertiaryText)
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        }
                        Spacer()
                        Text("\(TimeText.number(entry.value, digits: 2)) \(entry.kind.unit)")
                            .font(.subheadline.monospacedDigit())
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(filtered[index]) }
                }
            }
            .listRowBackground(Theme.card)
        }
        .winterScreen()
        .navigationTitle("記録の履歴")
        .navigationBarTitleDisplayMode(.inline)
    }
}
