import SwiftData
import SwiftUI

/// The "Your items" grid under the machine: one `ItemCardView` per saved item, then an "Add item" card.
///
/// Long-pressing a card offers "Edit", which opens the editor sheet for that item.
struct ItemGridView: View {
    let items: [ClothingItem]
    let isInFlight: (UUID) -> Bool
    let onTap: (ClothingItem) -> Void
    let onAdd: () -> Void

    @State private var editingItem: ClothingItem? = nil

    init(
        items: [ClothingItem],
        isInFlight: @escaping (UUID) -> Bool,
        onTap: @escaping (ClothingItem) -> Void,
        onAdd: @escaping () -> Void
    ) {
        self.items = items
        self.isInFlight = isInFlight
        self.onTap = onTap
        self.onAdd = onAdd
    }

    private var columns: [GridItem] {
        return [GridItem(.adaptive(minimum: 104), spacing: 12)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your items")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    ItemCardView(
                        item: item,
                        isInDrum: item.isInDrum,
                        isInFlight: isInFlight(item.uuid),
                        action: { onTap(item) }
                    )
                    .contextMenu {
                        Button {
                            editingItem = item
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
                AddItemCard(action: onAdd)
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditorSheet(editing: item)
        }
    }
}

/// The dashed "Add item" card at the end of the grid.
private struct AddItemCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                Text("Add item")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add item")
        .accessibilityHint("Double tap to create a new item")
    }
}
