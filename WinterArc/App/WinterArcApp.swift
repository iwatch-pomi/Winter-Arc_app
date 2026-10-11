import SwiftUI
import SwiftData

@main
struct WinterArcApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            TaskItem.self,
            Habit.self,
            HabitLog.self,
            LogEntry.self,
            Goal.self,
        ])
    }
}
