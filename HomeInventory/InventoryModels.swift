import Foundation
import SwiftData

enum StockStatus: String, Codable, CaseIterable {
    case inStock = "In Stock"
    case low = "Low"
    case out = "Out"
    case needsReview = "Needs Review"
}

enum InventoryAction: String, Codable, CaseIterable {
    case added, removed, opened, moved, purchased, markedEmpty, corrected, undone
}

enum ThresholdMode: String, Codable, CaseIterable, Identifiable {
    case household, location, both, disabled
    var id: String { rawValue }
}

@Model
final class Product {
    var name: String
    var brand: String
    var primaryCategory: String
    var subcategory: String
    var photoURL: String?
    var customPhotoData: Data?
    var householdLowThreshold: Double
    var openedLowPercentage: Int
    var openedOutPercentage: Int
    var thresholdModeRawValue: String
    var tagsText: String
    var preferredStoresText: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PackageVariant.product)
    var packageVariants: [PackageVariant]

    var thresholdMode: ThresholdMode {
        get { ThresholdMode(rawValue: thresholdModeRawValue) ?? .household }
        set { thresholdModeRawValue = newValue.rawValue }
    }

    var tags: [String] {
        tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var preferredStores: [String] {
        preferredStoresText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    init(name: String, brand: String = "", primaryCategory: String = "Other", subcategory: String = "",
         householdLowThreshold: Double = 1, openedLowPercentage: Int = 25,
         openedOutPercentage: Int = 0, thresholdMode: ThresholdMode = .household,
         tagsText: String = "", preferredStoresText: String = "") {
        self.name = name
        self.brand = brand
        self.primaryCategory = primaryCategory
        self.subcategory = subcategory
        self.householdLowThreshold = householdLowThreshold
        self.openedLowPercentage = openedLowPercentage
        self.openedOutPercentage = openedOutPercentage
        self.thresholdModeRawValue = thresholdMode.rawValue
        self.tagsText = tagsText
        self.preferredStoresText = preferredStoresText
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.packageVariants = []
    }
}

@Model
final class PackageVariant {
    var barcode: String
    var packageDescription: String
    var unitsPerPackage: Double
    var unitName: String
    var createdAt: Date
    var product: Product?

    init(barcode: String, packageDescription: String, unitsPerPackage: Double = 1, unitName: String = "item") {
        self.barcode = barcode
        self.packageDescription = packageDescription
        self.unitsPerPackage = unitsPerPackage
        self.unitName = unitName
        self.createdAt = Date()
    }
}
