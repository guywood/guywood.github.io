import SwiftData
import SwiftUI

/// Every saved item: search, reorder, swipe to delete, and tap to edit.
struct ItemsLibraryView: View {
    @Query(sort: \ClothingItem.sortOrder) private var items: [ClothingItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @State private var searchText = ""
    @State private var editingItem: ClothingItem?
    @State private var isAdding = false

    /// The items matching the search text, in sort order. Everything when the search is empty.
    private var filtered: [ClothingItem] {
        let query: String = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return items
        }
        return items.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    /// Reordering is only meaningful on the full, unfiltered list.
    private var moveAction: ((IndexSet, Int) -> Void)? {
        if searchText.isEmpty {
            return move(from:to:)
        }
        return nil
    }

    var body: some View {
        // The List stays mounted even when empty so the Edit button and edit mode behave.
        List {
            ForEach(filtered) { item in
                Button {
                    editingItem = item
                } label: {
                    ItemLibraryRow(item: item)
                }
            }
            .onDelete(perform: delete(at:))
            .onMove(perform: moveAction)
        }
        .searchable(text: $searchText, prompt: "Search items")
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "No items yet",
                    systemImage: "tshirt",
                    description: Text("Add the clothes you wash most often.")
                )
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .onChange(of: items.isEmpty) { _, isEmpty in
            if isEmpty {
                editMode?.wrappedValue = .inactive
            }
        }
        .navigationTitle("Items")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()
                    .disabled(items.isEmpty)
                Button {
                    isAdding = true
                } label: {
                    Label("Add item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAdding) {
            ItemEditorSheet(editing: nil)
        }
        .sheet(item: $editingItem) { item in
            ItemEditorSheet(editing: item)
        }
    }

    // MARK: - Actions

    /// Deletes the swiped rows. Offsets refer to `filtered`, which is what the list shows.
    private func delete(at offsets: IndexSet) {
        let visible: [ClothingItem] = filtered
        for index in offsets where visible.indices.contains(index) {
            modelContext.delete(visible[index])
        }
        try? modelContext.save()
    }

    /// Reorders the full list and rewrites every item's `sortOrder` to match.
    private func move(from source: IndexSet, to destination: Int) {
        var reordered: [ClothingItem] = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() where item.sortOrder != index {
            item.sortOrder = index
        }
        try? modelContext.save()
    }
}

/// One row in the items list: icon, name, a one-line summary, quantity and drum status.
private struct ItemLibraryRow: View {
    let item: ClothingItem

    var body: some View {
        HStack(spacing: 12) {
            ItemIconView(icon: item.icon, size: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if item.isInDrum {
                Text("In drum")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.18), in: Capsule())
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// "Darks · Medium · Medium bleed · Wool / cashmere"
    private var caption: String {
        var parts: [String] = [
            item.colourGroup.shortName,
            item.fabricWeight.displayName,
            "\(item.bleedRisk.displayName) bleed",
        ]
        for flag in item.flags.elements {
            parts.append(flag.displayName)
        }
        return parts.joined(separator: " · ")
    }
}
