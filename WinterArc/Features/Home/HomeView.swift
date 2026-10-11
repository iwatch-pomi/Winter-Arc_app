import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: AppTab

    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.startMinutes) private var tasks: [TaskItem]
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query(sort: \LogEntry.date) private var logs: [LogEntry]
    @Query(sort: \Goal.createdAt) private var goals: [Goal]

    @AppStorage(SettingsKey.seasonStart) private var seasonStart: Double = 0
    @AppStorage(SettingsKey.seasonEnd) private var seasonEnd: Double = 0
    @AppStorage(SettingsKey.userName) private var userName = ""

    @State private var showFocus = false
    @State private var showQuote = false

    private var season: Season { Season(start: seasonStart, end: seasonEnd) }
    private var thisWeek: DateInterval { RecordPeriod.week.interval(containing: Date()) }
    private var todayTasks: [TaskItem] { tasks.filter { $0.day.isToday } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    hero
                    weeklyProgress
                    quickActions
                    todayPreview
                    goalsPreview
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .winterScreen()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .schedule: TodayScheduleView()
                case .goals: GoalsView()
                }
            }
            .fullScreenCover(isPresented: $showFocus) { FocusView() }
            #if DEBUG
            .onAppear {
                switch UserDefaults.standard.string(forKey: "openScreen") {
                case "focus": showFocus = true
                case "quote": showQuote = true
                default: break
                }
            }
            #endif
            .sheet(isPresented: $showQuote) { DailyQuoteView() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            LogoView(size: 20)
            Spacer()
            Button {
                showQuote = true
            } label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("今日の名言とハイライト")
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            MountainArtView()
            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Date().text("M.d"))
                        .font(.system(size: 34, weight: .regular, design: .serif))
                    Text(Date().text("EEE", english: true))
                        .font(.system(size: 18, design: .serif))
                }
                Text(Quotes.tagline())
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .lineSpacing(6)
                if !userName.isEmpty {
                    Text("\(userName)さん、今日もいきましょう。")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                seasonBadge
            }
            .padding(20)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Theme.stroke, lineWidth: 1))
    }

    private var seasonBadge: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                if season.hasNotStarted {
                    Text("開始まで あと\(Date().days(until: season.start))日")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("DAY")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.secondaryText)
                    Text("\(season.dayNumber())")
                        .font(Theme.number(22))
                    Text("/ \(season.totalDays)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Text("残り\(season.remainingDays())日")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            ProgressBar(value: season.progress(), height: 4)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var weeklyProgress: some View {
        let weekTasks = tasks.tasks(in: thisWeek)
        let done = weekTasks.filter(\.isDone).count
        let habitWeek = HabitStats.week(habits: habits)
        let study = logs.total(.study, in: thisWeek)

        return VStack(alignment: .leading, spacing: 16) {
            Button {
                selectedTab = .records
            } label: {
                HStack {
                    Text("今週の進捗")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: 0) {
                stat(title: "タスク完了", value: "\(done)", suffix: "/\(weekTasks.count)")
                divider
                stat(title: "習慣達成", value: "\(habitWeek.perfectDays)", suffix: "/7")
                divider
                stat(title: "勉強時間", value: TimeText.number(study), suffix: "h")
            }

            Button {
                selectedTab = .tasks
            } label: {
                HStack(spacing: 8) {
                    Text("今日のタスクを見る")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .card()
    }

    private func stat(title: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
            StatValue(value: value, suffix: suffix, size: 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(width: 1, height: 44)
            .padding(.horizontal, 10)
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            Button {
                showFocus = true
            } label: {
                quickTile(icon: "timer", title: "集中モード", caption: "ポモドーロで記録")
            }
            NavigationLink(value: HomeRoute.schedule) {
                quickTile(icon: "list.bullet.rectangle", title: "今日の予定", caption: "スケジュール一覧")
            }
            Button {
                showQuote = true
            } label: {
                quickTile(icon: "quote.opening", title: "今日の名言", caption: "ハイライトも確認")
            }
            NavigationLink(value: HomeRoute.goals) {
                quickTile(icon: "scope", title: "目標", caption: "\(goals.filter { !$0.isAchieved }.count)件 進行中")
            }
        }
        .buttonStyle(.plain)
    }

    private func quickTile(icon: String, title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.elevated))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .card(padding: 14)
    }

    private var todayPreview: some View {
        let remaining = todayTasks.filter { !$0.isDone }
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "次のタスク", trailing: "\(todayTasks.filter(\.isDone).count)/\(todayTasks.count) 完了")
            if todayTasks.isEmpty {
                Text("今日のタスクはまだありません。タスクタブから追加しましょう。")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            } else if remaining.isEmpty {
                Label("今日のタスクはすべて完了！", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
            } else {
                ForEach(remaining.prefix(3)) { task in
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { task.toggle() }
                        } label: {
                            Image(systemName: "circle")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        Text(task.timeText)
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 48, alignment: .leading)
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
        }
        .card()
    }

    @ViewBuilder
    private var goalsPreview: some View {
        let active = goals.filter { !$0.isAchieved }
        if !active.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "今シーズンの目標")
                ForEach(active.prefix(3)) { goal in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: goal.isLongTerm ? "scope" : "flag")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                            .frame(width: 18)
                        Text(goal.title)
                            .font(.subheadline)
                    }
                }
            }
            .card()
        }
    }
}

enum HomeRoute: Hashable {
    case schedule
    case goals
}
