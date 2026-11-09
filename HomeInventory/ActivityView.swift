import SwiftUI
import SwiftData

struct ActivityView: View {
    @Query(sort: \ActivityEntry.createdAt, order: .reverse) private var entries: [ActivityEntry]
    var body: some View {
        NavigationStack {
            List(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack { Text(entry.productName).font(.headline); Spacer(); Text(entry.createdAt, style: .relative).font(.caption).foregroundStyle(.secondary) }
                    Text(entry.detail)
                    if !entry.locationName.isEmpty { Text(entry.locationName).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .overlay { if entries.isEmpty { ContentUnavailableView("No Activity Yet", systemImage: "clock") } }
            .navigationTitle("Activity")
        }
    }
}
