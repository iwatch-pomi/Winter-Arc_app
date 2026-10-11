import SwiftUI

enum AppTab: Hashable {
    case home, tasks, habits, records, settings
}

struct RootView: View {
    @AppStorage(SettingsKey.onboardingCompleted) private var onboardingCompleted = false
    @AppStorage(SettingsKey.seasonStart) private var seasonStart: Double = 0
    @AppStorage(SettingsKey.seasonEnd) private var seasonEnd: Double = 0
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(selectedTab: $selection)
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(AppTab.home)
            TasksView()
                .tabItem { Label("タスク", systemImage: "checkmark.square") }
                .tag(AppTab.tasks)
            HabitsView()
                .tabItem { Label("習慣", systemImage: "flame") }
                .tag(AppTab.habits)
            RecordsView()
                .tabItem { Label("記録", systemImage: "chart.bar.fill") }
                .tag(AppTab.records)
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(.white)
        .onAppear(perform: ensureSeason)
        .fullScreenCover(isPresented: Binding(
            get: { !onboardingCompleted },
            set: { onboardingCompleted = !$0 }
        )) {
            OnboardingView()
        }
    }

    private func ensureSeason() {
        guard seasonStart == 0 || seasonEnd == 0 else { return }
        let start = Date().startOfDay
        seasonStart = start.timeIntervalSinceReferenceDate
        seasonEnd = start.adding(days: Season.defaultLength - 1).timeIntervalSinceReferenceDate
    }
}
