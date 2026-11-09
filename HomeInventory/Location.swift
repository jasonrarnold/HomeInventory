import Foundation
import SwiftData

@Model
final class InventoryLocation {
    var name: String
    var sortOrder: Int
    var isArchived: Bool
    var createdAt: Date

    init(name: String, sortOrder: Int = 0, isArchived: Bool = false) {
        self.name = name
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.createdAt = Date()
    }
}
