import SwiftData
import SwiftUI

/// The Settings tab: feedback preferences, the scoring explainer, a library reset and app info.
///
/// Main-actor isolated (like `LoadScreen`) so the reset action can fire a haptic from a view
/// method: `Haptics` is `@MainActor`.
@MainActor
struct SettingsView: View {
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.showNumericScores) private var showNumericScores = false
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirmingReset = false

    /// The marketing version from the bundle, falling back to "1.0" when it is not set.
    private var versionString: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        Form {
            Section("Feedback") {
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Show scores as numbers", isOn: $showNumericScores)
            }

            Section("Scoring") {
                NavigationLink("How scoring works") {
                    HowScoringWorksView(weights: .default)
                }
            }

            Section {
                Button("Reset to starter items", role: .destructive) {
                    isConfirmingReset = true
                }
            } header: {
                Text("Library")
            } footer: {
                Text("Deletes every saved item and brings back the original starter set.")
            }

            Section("About") {
                LabeledContent("Version", value: versionString)
                Text("Wash Check scores a laundry load for colour bleeding and fabric clashes before you run it. Everything stays on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Replace all items with the starter set?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                resetLibrary()
            }
        } message: {
            Text("Your saved items will be deleted. This cannot be undone.")
        }
    }

    /// Replaces the library with the starter items and confirms with a haptic.
    private func resetLibrary() {
        ClothingItem.resetToStarters(in: modelContext)
        Haptics.notify(.success)
    }
}
