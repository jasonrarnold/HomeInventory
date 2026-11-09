import SwiftUI
import SwiftData

@main
struct HomeInventoryApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: [
                InventoryLocation.self,
                Product.self,
                PackageVariant.self,
                InventoryStock.self,
                ShoppingItem.self,
                ActivityEntry.self
            ])
    }
}
