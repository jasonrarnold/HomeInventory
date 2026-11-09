import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(filter: #Predicate<InventoryLocation> { !$0.isArchived }, sort: \InventoryLocation.sortOrder) private var locations: [InventoryLocation]
    @Query private var stocks: [InventoryStock]
    @State private var editingLocation: InventoryLocation?
    @State private var showingNewLocation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Household Overview") {
                    statusRow("Low Stock", count: stocks.filter { $0.status == .low }.count, icon: "exclamationmark.triangle", color: .orange)
                    statusRow("Out of Stock", count: stocks.filter { $0.status == .out }.count, icon: "xmark.circle", color: .red)
                    statusRow("Needs Review", count: stocks.filter { $0.status == .needsReview }.count, icon: "questionmark.circle", color: .purple)
                }
                Section("Storage Locations") {
                    ForEach(locations) { location in
                        Button(location.name) { editingLocation = location }
                            .swipeActions { Button("Archive", role: .destructive) { location.isArchived = true } }
                    }
                    .onMove { source, destination in
                        var reordered = locations
                        reordered.move(fromOffsets: source, toOffset: destination)
                        for (index, location) in reordered.enumerated() { location.sortOrder = index }
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) { Button("Add Location", systemImage: "plus") { showingNewLocation = true } }
            }
            .sheet(isPresented: $showingNewLocation) { LocationEditorView(location: nil) }
            .sheet(item: $editingLocation) { LocationEditorView(location: $0) }
        }
    }

    private func statusRow(_ title: String, count: Int, icon: String, color: Color) -> some View {
        HStack { Image(systemName: icon).foregroundStyle(color); Text(title); Spacer(); Text("\(count)").foregroundStyle(.secondary) }
    }
}

struct LocationEditorView: View {
    let location: InventoryLocation?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<InventoryLocation> { !$0.isArchived }) private var locations: [InventoryLocation]
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form { TextField("Location name", text: $name) }
                .navigationTitle(location == nil ? "New Location" : "Edit Location")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
                }
                .onAppear { name = location?.name ?? "" }
        }
    }

    private func save() {
        let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let location { location.name = value } else { modelContext.insert(InventoryLocation(name: value, sortOrder: locations.count)) }
        dismiss()
    }
}
