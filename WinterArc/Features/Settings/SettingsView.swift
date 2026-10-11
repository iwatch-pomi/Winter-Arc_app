import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(SettingsKey.userName) private var userName = ""
    @AppStorage(SettingsKey.targetWeight) private var targetWeight: Double = 0
    @AppStorage(SettingsKey.seasonStart) private var seasonStart: Double = 0
    @AppStorage(SettingsKey.seasonEnd) private var seasonEnd: Double = 0
    @AppStorage(SettingsKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(SettingsKey.reminderMinutes) private var reminderMinutes = 21 * 60
    @AppStorage(SettingsKey.focusMinutes) private var focusMinutes = 25
    @AppStorage(SettingsKey.onboardingCompleted) private var onboardingCompleted = true

    @State private var targetWeightText = ""
    @State private var confirmReset = false
    @State private var notificationDenied = false

    private var season: Season { Season(start: seasonStart, end: seasonEnd) }

    var body: some View {
        NavigationStack {
            Form {
                Section("プロフィール") {
                    TextField("ニックネーム", text: $userName)
                    HStack {
                        Text("目標体重")
                        Spacer()
                        TextField("未設定", text: $targetWeightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .onChange(of: targetWeightText) { _, newValue in
                                targetWeight = Double(newValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                            }
                        Text("kg").foregroundStyle(Theme.secondaryText)
                    }
                }

                Section {
                    DatePicker("開始日", selection: dateBinding($seasonStart), displayedComponents: .date)
                    DatePicker("終了日", selection: dateBinding($seasonEnd), in: season.start..., displayedComponents: .date)
                    LabeledContent("期間", value: "\(season.totalDays)日間")
                    LabeledContent("進捗", value: season.hasNotStarted ? "開始前" : "Day \(season.dayNumber()) / \(season.totalDays)")
                } header: {
                    Text("シーズン（挑戦期間）")
                } footer: {
                    Text("Winter Arc は一般的に 10月〜12月末の約90日間。自分のペースで期間を決めましょう。")
                }
                .environment(\.locale, Locale(identifier: "ja_JP"))

                Section("目標") {
                    NavigationLink {
                        GoalsView()
                    } label: {
                        Label("目標を管理", systemImage: "scope")
                    }
                }

                Section {
                    Toggle("毎日のリマインダー", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            updateReminder(enabled: enabled)
                        }
                    if reminderEnabled {
                        DatePicker("通知時刻", selection: reminderBinding, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderMinutes) { _, _ in
                                updateReminder(enabled: true)
                            }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    if notificationDenied {
                        Text("通知が許可されていません。iPhoneの「設定」→「Winter Arc」→「通知」から許可してください。")
                    }
                }

                Section("集中モード") {
                    Stepper("1セッション \(focusMinutes)分", value: $focusMinutes, in: 5...120, step: 5)
                }

                Section("データ") {
                    Button("目標設定（はじめの画面）をやり直す") {
                        onboardingCompleted = false
                    }
                    Button("すべてのデータを削除", role: .destructive) {
                        confirmReset = true
                    }
                }

                Section {
                    LabeledContent("バージョン", value: appVersion)
                } footer: {
                    VStack(spacing: 6) {
                        LogoView(size: 16)
                        Text("Discipline today, Freedom tomorrow.")
                            .font(.caption.italic())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .foregroundStyle(Theme.secondaryText)
                }
            }
            .winterScreen()
            .navigationTitle("設定")
            .onAppear {
                targetWeightText = targetWeight > 0 ? TimeText.number(targetWeight) : ""
            }
            .confirmationDialog("すべてのタスク・習慣・記録・目標を削除します。元に戻せません。", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("削除する", role: .destructive, action: resetAll)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    private func dateBinding(_ storage: Binding<Double>) -> Binding<Date> {
        Binding(
            get: { storage.wrappedValue == 0 ? Date().startOfDay : Date(timeIntervalSinceReferenceDate: storage.wrappedValue) },
            set: { storage.wrappedValue = $0.startOfDay.timeIntervalSinceReferenceDate }
        )
    }

    private var reminderBinding: Binding<Date> {
        Binding(
            get: { Date().startOfDay.addingTimeInterval(Double(reminderMinutes * 60)) },
            set: {
                let c = Calendar.app.dateComponents([.hour, .minute], from: $0)
                reminderMinutes = (c.hour ?? 21) * 60 + (c.minute ?? 0)
            }
        )
    }

    private func updateReminder(enabled: Bool) {
        guard enabled else {
            NotificationManager.cancelDailyReminder()
            return
        }
        Task {
            let granted = await NotificationManager.requestAuthorization()
            if granted {
                notificationDenied = false
                NotificationManager.scheduleDailyReminder(minutesOfDay: reminderMinutes)
            } else {
                notificationDenied = true
                reminderEnabled = false
            }
        }
    }

    private func resetAll() {
        deleteAll(HabitLog.self)
        deleteAll(Habit.self)
        deleteAll(TaskItem.self)
        deleteAll(LogEntry.self)
        deleteAll(Goal.self)
        try? context.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        let items = (try? context.fetch(FetchDescriptor<T>())) ?? []
        for item in items {
            context.delete(item)
        }
    }
}
