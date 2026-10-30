import SwiftUI

/// The app's top level: three tabs, each wrapped in its own navigation stack.
struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LoadScreen()
            }
            .tabItem {
                Label("Load", systemImage: "washer")
            }

            NavigationStack {
                ItemsLibraryView()
            }
            .tabItem {
                Label("Items", systemImage: "tshirt")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}
