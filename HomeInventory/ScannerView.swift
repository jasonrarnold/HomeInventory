import SwiftUI
import VisionKit

struct ScannerView: View {
    @State private var scannedBarcode: String?
    @State private var showingManual = false

    var body: some View {
        NavigationStack {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    BarcodeScannerRepresentable { code in
                        scannedBarcode = code
                    }
                    .ignoresSafeArea(edges: .bottom)
                } else {
                    ContentUnavailableView(
                        "Scanner Unavailable",
                        systemImage: "barcode.viewfinder",
                        description: Text("Use manual entry on this device.")
                    )
                }
            }
            .navigationTitle("Scan")
            .toolbar {
                Button("Manual Entry") { showingManual = true }
            }
            .sheet(isPresented: $showingManual) {
                ProductEditorView(barcode: nil)
            }
            .sheet(item: Binding(
                get: { scannedBarcode.map(BarcodeValue.init) },
                set: { if $0 == nil { scannedBarcode = nil } }
            )) { value in
                BarcodeResultView(barcode: value.value)
            }
        }
    }
}

private struct BarcodeValue: Identifiable {
    let value: String
    var id: String { value }
}

struct BarcodeResultView: View {
    let barcode: String
    @State private var lookup: LookupProduct?
    @State private var loading = true

    var body: some View {
        Group {
            if loading {
                ProgressView("Looking up product...")
            } else {
                ProductEditorView(
                    barcode: barcode,
                    lookupName: lookup?.name,
                    lookupBrand: lookup?.brand
                )
            }
        }
        .task {
            lookup = try? await ProductLookupService.lookup(barcode: barcode)
            loading = false
        }
    }
}

private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                if case let .barcode(code) = item,
                   let value = code.payloadStringValue {
                    dataScanner.stopScanning()
                    onScan(value)
                    return
                }
            }
        }
    }
}

struct LookupProduct: Hashable {
    let name: String?
    let brand: String?
    let imageURL: String?
}

private struct OpenFoodFactsEnvelope: Decodable {
    let status: Int
    let product: ProductData?

    struct ProductData: Decodable {
        let product_name: String?
        let brands: String?
        let image_front_url: String?
    }
}

enum ProductLookupService {
    static func lookup(barcode: String) async throws -> LookupProduct? {
        for candidate in barcodeCandidates(for: barcode) {
            if let product = try await lookupOpenFoodFacts(barcode: candidate) {
                return product
            }
        }
        return nil
    }

    private static func barcodeCandidates(for barcode: String) -> [String] {
        let digits = barcode.filter(\.isNumber)
        var candidates = [digits]

        if digits.count == 13 && digits.first == "0" {
            candidates.append(String(digits.dropFirst()))
        }

        return Array(NSOrderedSet(array: candidates)) as? [String] ?? candidates
    }

    private static func lookupOpenFoodFacts(barcode: String) async throws -> LookupProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("HomeInventory/1.0 (iOS; personal household inventory)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        let decoded = try JSONDecoder().decode(OpenFoodFactsEnvelope.self, from: data)
        guard decoded.status == 1,
              let product = decoded.product,
              !(product.product_name ?? "").isEmpty else {
            return nil
        }

        return LookupProduct(
            name: product.product_name,
            brand: product.brands,
            imageURL: product.image_front_url
        )
    }
}
