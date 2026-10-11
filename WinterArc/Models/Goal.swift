import Foundation
import SwiftData

@Model
final class Goal {
    var title: String = ""
    var isLongTerm: Bool = true
    var isAchieved: Bool = false
    var createdAt: Date = Date()

    init(title: String, isLongTerm: Bool = true) {
        self.title = title
        self.isLongTerm = isLongTerm
        self.createdAt = Date()
    }
}
