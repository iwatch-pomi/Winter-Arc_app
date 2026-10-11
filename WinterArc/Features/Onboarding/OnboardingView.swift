import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(SettingsKey.onboardingCompleted) private var onboardingCompleted = false
    @AppStorage(SettingsKey.seasonStart) private var seasonStart: Double = 0
    @AppStorage(SettingsKey.seasonEnd) private var seasonEnd: Double = 0
    @AppStorage(SettingsKey.userName) private var userName = ""

    @Query private var existingHabits: [Habit]

    @State private var step = 0
    @State private var goals = ["", "", ""]
    @State private var start = Date().startOfDay
    @State private var end = Date().startOfDay.adding(days: Season.defaultLength - 1)
    @State private var selectedPresets = HabitPreset.defaultSelection
    @FocusState private var focusedField: Int?

    private let goalExamples = ["例）大学に合格する", "例）英語を話せるようになる", "例）体を鍛えて健康になる"]
    private let lastStep = 3

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch step {
                    case 0: welcomeStep
                    case 1: goalStep
                    case 2: seasonStep
                    default: habitStep
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollDismissesKeyboard(.interactively)
            Button(step == lastStep ? "はじめる" : "次へ", action: next)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            if seasonStart != 0 { start = Date(timeIntervalSinceReferenceDate: seasonStart) }
            if seasonEnd != 0 { end = Date(timeIntervalSinceReferenceDate: seasonEnd) }
        }
    }

    private var navigationBar: some View {
        ZStack {
            Text(["Winter Arc", "目標設定", "期間設定", "習慣を選ぶ"][step])
                .font(.headline)
            HStack {
                if step > 0 {
                    Button {
                        withAnimation { step -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                    }
                }
                Spacer()
                if step > 0 {
                    Button("スキップ", action: skip)
                        .font(.subheadline)
                }
            }
            .foregroundStyle(.white)
        }
        .frame(height: 52)
        .padding(.horizontal, 12)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            MountainArtView()
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            LogoView(size: 26)
            Text("冬の努力が、\n最高の自分をつくる。")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .lineSpacing(8)
            Text("Winter Arc は、あなたの「冬の挑戦期間」を管理する自己成長アプリです。目標設定・タスク管理・習慣化・記録を通して、理想の自分に近づくためのサポートをします。")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .lineSpacing(5)
            TextField("ニックネーム（任意）", text: $userName)
                .padding(14)
                .background(Capsule().stroke(Theme.stroke, lineWidth: 1))
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今シーズンの目標を\n設定しましょう")
                .font(.title2.weight(.semibold))
                .lineSpacing(6)
            Text("大きな目標でも、小さな目標でも構いません。\nまずは一歩から。")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            ForEach(goals.indices, id: \.self) { index in
                TextField(goalExamples[index], text: $goals[index])
                    .focused($focusedField, equals: index)
                    .submitLabel(index == goals.count - 1 ? .done : .next)
                    .onSubmit { focusedField = index + 1 < goals.count ? index + 1 : nil }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Theme.card))
                    .overlay(Capsule().stroke(Theme.stroke, lineWidth: 1))
            }
        }
    }

    private var seasonStep: some View {
        let season = Season(start: start.timeIntervalSinceReferenceDate, end: end.timeIntervalSinceReferenceDate)
        return VStack(alignment: .leading, spacing: 16) {
            Text("挑戦する期間を\n決めましょう")
                .font(.title2.weight(.semibold))
                .lineSpacing(6)
            Text("Winter Arc は一般的に年末までの約90日間。\n期間を区切ることで、集中力が高まります。")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            VStack(spacing: 0) {
                DatePicker("開始日", selection: $start, displayedComponents: .date)
                    .padding(.vertical, 8)
                Divider()
                DatePicker("終了日", selection: $end, in: start..., displayedComponents: .date)
                    .padding(.vertical, 8)
            }
            .environment(\.locale, Locale(identifier: "ja_JP"))
            .card()
            HStack {
                presetButton("90日") { end = start.adding(days: 89) }
                presetButton("66日") { end = start.adding(days: 65) }
                presetButton("年末まで") {
                    let year = Calendar.app.component(.year, from: start)
                    if let dec31 = Calendar.app.date(from: DateComponents(year: year, month: 12, day: 31)) {
                        end = dec31
                    }
                }
            }
            Text("期間：\(season.totalDays)日間")
                .font(.headline)
        }
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(SecondaryButtonStyle())
    }

    private var habitStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("毎日続けたい習慣を\n選びましょう")
                .font(.title2.weight(.semibold))
                .lineSpacing(6)
            Text("あとから追加・変更できます。")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            ForEach(HabitPreset.all) { preset in
                let selected = selectedPresets.contains(preset.name)
                Button {
                    if selected {
                        selectedPresets.remove(preset.name)
                    } else {
                        selectedPresets.insert(preset.name)
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: preset.icon)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Theme.elevated))
                        Text(preset.name)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selected ? Color.white : Theme.tertiaryText)
                    }
                    .card(padding: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Flow

    private func next() {
        focusedField = nil
        if step < lastStep {
            withAnimation { step += 1 }
        } else {
            finish(addHabits: true)
        }
    }

    private func skip() {
        focusedField = nil
        if step == 1 { goals = ["", "", ""] }
        if step < lastStep {
            withAnimation { step += 1 }
        } else {
            finish(addHabits: false)
        }
    }

    private func finish(addHabits: Bool) {
        for title in goals.map({ $0.trimmingCharacters(in: .whitespaces) }) where !title.isEmpty {
            context.insert(Goal(title: title, isLongTerm: true))
        }
        seasonStart = start.startOfDay.timeIntervalSinceReferenceDate
        seasonEnd = max(end, start).startOfDay.timeIntervalSinceReferenceDate

        if addHabits {
            let existingNames = Set(existingHabits.map(\.name))
            var order = (existingHabits.map(\.sortOrder).max() ?? -1) + 1
            for preset in HabitPreset.all where selectedPresets.contains(preset.name) && !existingNames.contains(preset.name) {
                context.insert(Habit(name: preset.name, icon: preset.icon, sortOrder: order))
                order += 1
            }
        }
        try? context.save()
        onboardingCompleted = true
    }
}
