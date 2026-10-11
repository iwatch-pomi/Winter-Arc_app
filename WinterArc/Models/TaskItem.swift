import Foundation
import SwiftData

enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case study = "勉強"
    case workout = "筋トレ"
    case life = "生活"
    case other = "その他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .study: "book.fill"
        case .workout: "dumbbell.fill"
        case .life: "sun.max.fill"
        case .other: "circle.grid.2x2.fill"
        }
    }
}

@Model
final class TaskItem {
    var title: String = ""
    /// その日の 0:00
    var day: Date = Date()
    /// 0:00 からの分（15分単位）
    var startMinutes: Int = 540
    var durationMinutes: Int = 30
    var categoryRaw: String = TaskCategory.other.rawValue
    var isDone: Bool = false
    var completedAt: Date?
    var note: String = ""
    var createdAt: Date = Date()

    init(
        title: String,
        day: Date,
        startMinutes: Int,
        durationMinutes: Int = 30,
        category: TaskCategory = .other,
        note: String = ""
    ) {
        self.title = title
        self.day = day.startOfDay
        self.startMinutes = startMinutes
        self.durationMinutes = durationMinutes
        self.categoryRaw = category.rawValue
        self.note = note
        self.createdAt = Date()
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var timeText: String { TimeText.clock(startMinutes) }

    func toggle() {
        isDone.toggle()
        completedAt = isDone ? Date() : nil
    }
}
