import SwiftData
import SwiftUI

@main
struct WashCheckApp: App {
    private let container: ModelContainer

    init() {
        AppSettings.registerDefaults()
        do {
            let container = try ModelContainer(for: ClothingItem.self)
            // Seed the starter items on a throwaway context so the first frame already has data.
            let seedContext = ModelContext(container)
            ClothingItem.seedIfNeeded(in: seedContext)
            self.container = container
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
