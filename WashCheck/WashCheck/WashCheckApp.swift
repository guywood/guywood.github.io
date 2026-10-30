import SwiftData
import SwiftUI

@main
struct WashCheckApp: App {
    private let container: ModelContainer

    init() {
        AppSettings.registerDefaults()
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ClothingItem.self)
        } catch {
            // Last resort: keep the app usable with an in-memory store rather than crashing at launch.
            let memoryOnly = ModelConfiguration(isStoredInMemoryOnly: true)
            guard let fallback = try? ModelContainer(for: ClothingItem.self, configurations: memoryOnly) else {
                fatalError("Could not create the SwiftData container: \(error)")
            }
            container = fallback
        }
        // Seed the starter items on a throwaway context so the first frame already has data.
        let seedContext = ModelContext(container)
        ClothingItem.seedIfNeeded(in: seedContext)
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
