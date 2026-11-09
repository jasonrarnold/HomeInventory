import Foundation
import SwiftData

@Model
final class InventoryStock {
    var sealedPackageCount: Int
    var openedPercentage: Int?
    var hasConflict: Bool
    var updatedAt: Date
    var product: Product?
    var packageVariant: PackageVariant?
    var location: InventoryLocation?

    init(product: Product, packageVariant: PackageVariant, location: InventoryLocation,
         sealedPackageCount: Int = 0, openedPercentage: Int? = nil, hasConflict: Bool = false) {
        self.product = product
        self.packageVariant = packageVariant
        self.location = location
        self.sealedPackageCount = max(0, sealedPackageCount)
        self.openedPercentage = openedPercentage.map { min(100, max(0, $0)) }
        self.hasConflict = hasConflict
        self.updatedAt = Date()
    }

    var status: StockStatus {
        if hasConflict { return .needsReview }
        guard let product else { return .out }
        if sealedPackageCount == 0 && (openedPercentage ?? 0) <= product.openedOutPercentage { return .out }
        if sealedPackageCount <= Int(product.householdLowThreshold) || (openedPercentage ?? 100) <= product.openedLowPercentage { return .low }
        return .inStock
    }
}

@Model
final class ShoppingItem {
    var productName: String
    var storeName: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var product: Product?

    init(product: Product, storeName: String = "Unassigned") {
        self.product = product
        self.productName = product.name
        self.storeName = storeName
        self.isCompleted = false
        self.createdAt = Date()
    }
}

@Model
final class ActivityEntry {
    var actionRawValue: String
    var productName: String
    var locationName: String
    var detail: String
    var memberName: String
    var reason: String
    var createdAt: Date

    var action: InventoryAction { InventoryAction(rawValue: actionRawValue) ?? .corrected }

    init(action: InventoryAction, productName: String, locationName: String = "", detail: String,
         memberName: String = "Household", reason: String = "") {
        self.actionRawValue = action.rawValue
        self.productName = productName
        self.locationName = locationName
        self.detail = detail
        self.memberName = memberName
        self.reason = reason
        self.createdAt = Date()
    }
}
