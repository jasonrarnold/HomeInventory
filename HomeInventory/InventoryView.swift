import SwiftUI
import SwiftData

struct InventoryView: View {
    @Query(filter: #Predicate<Product> { !$0.isArchived }, sort: \Product.name)
    private var products: [Product]

    @Query private var stocks: [InventoryStock]
    @State private var searchText = ""
    @State private var showingNewProduct = false

    private var filtered: [Product] {
        searchText.isEmpty ? products : products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { product in
                NavigationLink {
                    ProductDetailView(product: product)
                } label: {
                    VStack(alignment: .leading) {
                        Text(product.name).font(.headline)
                        Text([product.brand, product.primaryCategory]
                            .filter { !$0.isEmpty }
                            .joined(separator: " • "))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        let productStocks = stocks.filter {
                            $0.product?.persistentModelID == product.persistentModelID
                        }
                        Text(summary(productStocks))
                            .font(.caption)
                            .foregroundStyle(statusColor(productStocks))
                    }
                }
            }
            .overlay {
                if products.isEmpty {
                    ContentUnavailableView(
                        "No Products",
                        systemImage: "shippingbox",
                        description: Text("Tap + to create or scan a product.")
                    )
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText)
            .toolbar {
                Button("Add Product", systemImage: "plus") {
                    showingNewProduct = true
                }
            }
            .sheet(isPresented: $showingNewProduct) {
                ProductEditorView(barcode: nil)
            }
        }
    }

    private func summary(_ rows: [InventoryStock]) -> String {
        if rows.contains(where: { $0.hasConflict }) { return "Needs Review" }
        let sealed = rows.reduce(0) { $0 + $1.sealedPackageCount }
        let opened = rows.compactMap(\.openedPercentage)
        return "\(sealed) sealed" + (opened.isEmpty ? "" : " • opened \(opened.map(String.init).joined(separator: ", "))%")
    }

    private func statusColor(_ rows: [InventoryStock]) -> Color {
        if rows.contains(where: { $0.status == .needsReview }) { return .purple }
        if rows.contains(where: { $0.status == .out }) { return .red }
        if rows.contains(where: { $0.status == .low }) { return .orange }
        return .secondary
    }
}

struct ProductDetailView: View {
    let product: Product
    @Query private var stocks: [InventoryStock]
    @State private var showingAdjustment = false
    @State private var showingEditor = false

    private var productStocks: [InventoryStock] {
        stocks.filter { $0.product?.persistentModelID == product.persistentModelID }
    }

    var body: some View {
        List {
            Section("Product") {
                LabeledContent("Brand", value: product.brand.isEmpty ? "Not set" : product.brand)
                LabeledContent("Category", value: product.primaryCategory)
                LabeledContent("Low threshold", value: product.householdLowThreshold.formatted())
            }

            Section("Stock by Location") {
                if productStocks.isEmpty {
                    Text("No stock recorded").foregroundStyle(.secondary)
                }

                ForEach(productStocks) { row in
                    VStack(alignment: .leading) {
                        Text(row.location?.name ?? "Unknown Location").font(.headline)
                        Text("\(row.sealedPackageCount) sealed" + (row.openedPercentage.map { " • opened \($0)%" } ?? ""))
                        Text(row.status.rawValue)
                            .font(.caption)
                            .foregroundStyle(row.status == .out ? .red : row.status == .low ? .orange : .secondary)
                    }
                }
            }

            Section("Package Variants") {
                ForEach(product.packageVariants) { variant in
                    Text("\(variant.packageDescription) • \(variant.unitsPerPackage.formatted()) \(variant.unitName)")
                }
            }
        }
        .navigationTitle(product.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit", systemImage: "pencil") {
                    showingEditor = true
                }
                Button("Adjust Stock", systemImage: "plusminus") {
                    showingAdjustment = true
                }
            }
        }
        .sheet(isPresented: $showingAdjustment) {
            StockAdjustmentView(product: product)
        }
        .sheet(isPresented: $showingEditor) {
            ProductEditorView(
                barcode: product.packageVariants.first?.barcode,
                product: product
            )
        }
    }
}

struct ProductEditorView: View {
    let barcode: String?
    var product: Product? = nil
    var lookupName: String? = nil
    var lookupBrand: String? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var brand = ""
    @State private var category = "Other"
    @State private var packageDescription = "Standard package"
    @State private var units = 1.0
    @State private var unitName = "item"
    @State private var lowThreshold = 1.0
    @State private var tags = ""
    @State private var stores = ""

    private let categories = [
        "Pantry", "Refrigerator", "Freezer", "Laundry",
        "Cleaning Supplies", "Bathroom and Toiletries",
        "Paper Goods", "Pet Supplies", "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Product name", text: $name)
                    TextField("Brand", text: $brand)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    TextField("Tags, comma-separated", text: $tags)
                    TextField("Preferred stores, ranked", text: $stores)
                }

                Section("Package") {
                    LabeledContent("Barcode", value: barcode ?? "Manual entry")
                    TextField("Package description", text: $packageDescription)
                    TextField("Units per package", value: $units, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Unit name", text: $unitName)
                }

                Section("Low Stock") {
                    TextField("Sealed-package threshold", value: $lowThreshold, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(product == nil ? "New Product" : "Edit Product")
            .onAppear {
                if let product {
                    name = product.name
                    brand = product.brand
                    category = product.primaryCategory
                    lowThreshold = product.householdLowThreshold
                    tags = product.tagsText
                    stores = product.preferredStoresText

                    if let variant = product.packageVariants.first {
                        packageDescription = variant.packageDescription
                        units = variant.unitsPerPackage
                        unitName = variant.unitName
                    }
                } else {
                    if name.isEmpty { name = lookupName ?? "" }
                    if brand.isEmpty { brand = lookupBrand ?? "" }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPackage = packageDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanUnit = unitName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else { return }

        let defaults: (Int, Int) = switch category {
        case "Refrigerator", "Pet Supplies": (30, 5)
        case "Freezer": (20, 0)
        case "Laundry": (20, 5)
        case "Cleaning Supplies": (15, 5)
        case "Bathroom and Toiletries": (25, 5)
        default: (25, 0)
        }

        if let product {
            product.name = cleanName
            product.brand = cleanBrand
            product.primaryCategory = category
            product.householdLowThreshold = lowThreshold
            product.openedLowPercentage = defaults.0
            product.openedOutPercentage = defaults.1
            product.tagsText = tags
            product.preferredStoresText = stores
            product.updatedAt = Date()

            if let variant = product.packageVariants.first {
                variant.packageDescription = cleanPackage.isEmpty ? "Standard package" : cleanPackage
                variant.unitsPerPackage = max(1, units)
                variant.unitName = cleanUnit.isEmpty ? "item" : cleanUnit
            } else {
                let variant = PackageVariant(
                    barcode: barcode ?? "",
                    packageDescription: cleanPackage.isEmpty ? "Standard package" : cleanPackage,
                    unitsPerPackage: max(1, units),
                    unitName: cleanUnit.isEmpty ? "item" : cleanUnit
                )
                variant.product = product
                product.packageVariants.append(variant)
                modelContext.insert(variant)
            }

            modelContext.insert(ActivityEntry(
                action: .corrected,
                productName: product.name,
                detail: "Edited product details"
            ))
        } else {
            let newProduct = Product(
                name: cleanName,
                brand: cleanBrand,
                primaryCategory: category,
                householdLowThreshold: lowThreshold,
                openedLowPercentage: defaults.0,
                openedOutPercentage: defaults.1,
                tagsText: tags,
                preferredStoresText: stores
            )

            let variant = PackageVariant(
                barcode: barcode ?? "",
                packageDescription: cleanPackage.isEmpty ? "Standard package" : cleanPackage,
                unitsPerPackage: max(1, units),
                unitName: cleanUnit.isEmpty ? "item" : cleanUnit
            )

            variant.product = newProduct
            newProduct.packageVariants.append(variant)
            modelContext.insert(newProduct)
            modelContext.insert(variant)
        }

        dismiss()
    }
}

struct StockAdjustmentView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<InventoryLocation> { !$0.isArchived }, sort: \InventoryLocation.sortOrder)
    private var locations: [InventoryLocation]

    @State private var location: InventoryLocation?
    @State private var sealed = 0
    @State private var hasOpened = false
    @State private var opened = 100.0

    var body: some View {
        NavigationStack {
            Form {
                Picker("Location", selection: $location) {
                    Text("Choose").tag(nil as InventoryLocation?)
                    ForEach(locations) { Text($0.name).tag(Optional($0)) }
                }
                Stepper("Sealed packages: \(sealed)", value: $sealed, in: 0...999)
                Toggle("Opened container", isOn: $hasOpened)
                if hasOpened {
                    Slider(value: $opened, in: 0...100, step: 5)
                    Text("Opened: \(Int(opened))%")
                }
            }
            .navigationTitle("Adjust Stock")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(location == nil || product.packageVariants.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let location, let variant = product.packageVariants.first else { return }
        let row = InventoryStock(
            product: product,
            packageVariant: variant,
            location: location,
            sealedPackageCount: sealed,
            openedPercentage: hasOpened ? Int(opened) : nil
        )
        modelContext.insert(row)
        modelContext.insert(ActivityEntry(
            action: .added,
            productName: product.name,
            locationName: location.name,
            detail: "Set \(sealed) sealed" + (hasOpened ? " and opened \(Int(opened))%" : "")
        ))
        if row.status == .low || row.status == .out {
            modelContext.insert(ShoppingItem(
                product: product,
                storeName: product.preferredStores.first ?? "Unassigned"
            ))
        }
        dismiss()
    }
}
