import Foundation
import SwiftData

enum LogKind: String, CaseIterable, Identifiable, Codable {
    case study
    case exercise
    case weight
    case book
    case sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: "勉強時間"
        case .exercise: "運動時間"
        case .weight: "体重"
        case .book: "読書冊数"
        case .sleep: "睡眠時間"
        }
    }

    var unit: String {
        switch self {
        case .study, .sleep: "h"
        case .exercise: "分"
        case .weight: "kg"
        case .book: "冊"
        }
    }

    var inputUnit: String {
        switch self {
        case .study, .sleep: "時間"
        case .exercise: "分"
        case .weight: "kg"
        case .book: "冊"
        }
    }

    var icon: String {
        switch self {
        case .study: "pencil.and.outline"
        case .exercise: "figure.run"
        case .weight: "scalemass.fill"
        case .book: "books.vertical.fill"
        case .sleep: "bed.double.fill"
        }
    }

    var defaultValue: Double? {
        switch self {
        case .book: 1
        case .sleep: 7
        default: nil
        }
    }

    /// 期間内の値をどう集計するか
    func aggregate(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        switch self {
        case .weight: return values.last ?? 0
        case .sleep: return values.reduce(0, +) / Double(values.count)
        default: return values.reduce(0, +)
        }
    }
}

@Model
final class LogEntry {
    var kindRaw: String = LogKind.study.rawValue
    var value: Double = 0
    var date: Date = Date()
    var note: String = ""

    init(kind: LogKind, value: Double, date: Date = Date(), note: String = "") {
        self.kindRaw = kind.rawValue
        self.value = value
        self.date = date
        self.note = note
    }

    var kind: LogKind {
        get { LogKind(rawValue: kindRaw) ?? .study }
        set { kindRaw = newValue.rawValue }
    }
}
