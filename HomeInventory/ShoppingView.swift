import SwiftUI
import SwiftData

struct ShoppingView: View {
    @Query(sort: \ShoppingItem.createdAt) private var items: [ShoppingItem]
    @Environment(\.modelContext) private var modelContext

    var active: [ShoppingItem] { items.filter { !$0.isCompleted } }
    var grouped: [String: [ShoppingItem]] { Dictionary(grouping: active, by: \.storeName) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped.keys.sorted(), id: \.self) { store in
                    Section(store) {
                        ForEach(grouped[store] ?? []) { item in
                            Button { complete(item) } label: {
                                Label(item.productName, systemImage: "circle")
                            }.foregroundStyle(.primary)
                        }
                    }
                }
            }
            .overlay { if active.isEmpty { ContentUnavailableView("Shopping List Is Empty", systemImage: "cart") } }
            .navigationTitle("Shopping")
        }
    }

    private func complete(_ item: ShoppingItem) {
        item.isCompleted = true
        item.completedAt = Date()
        modelContext.insert(ActivityEntry(action: .purchased, productName: item.productName, detail: "Checked off at \(item.storeName)"))
    }
}
