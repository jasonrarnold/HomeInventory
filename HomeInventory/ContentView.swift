import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") { HomeView() }
            Tab("Scan", systemImage: "barcode.viewfinder") { ScannerView() }
            Tab("Inventory", systemImage: "shippingbox.fill") { InventoryView() }
            Tab("Shopping", systemImage: "cart.fill") { ShoppingView() }
            Tab("Activity", systemImage: "clock.fill") { ActivityView() }
        }
    }
}
