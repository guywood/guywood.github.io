import SwiftUI

/// Grid picker for an item's glyph: the curated emoji first, then the curated SF Symbols.
struct IconPickerView: View {
    @Binding var selection: ItemIcon

    private var columns: [GridItem] {
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Emoji")
                        .font(.headline)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(ItemIcon.curatedEmoji, id: \.self) { value in
                            let icon: ItemIcon = ItemIcon.emoji(value)
                            Button {
                                selection = icon
                                Haptics.selection()
                            } label: {
                                IconGlyphCell(icon: icon, isSelected: icon == selection)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(value)
                            .accessibilityAddTraits(icon == selection ? AccessibilityTraits.isSelected : AccessibilityTraits())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Symbols")
                        .font(.headline)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(ItemIcon.curatedSymbols, id: \.self) { name in
                            let icon: ItemIcon = ItemIcon.symbol(name)
                            Button {
                                selection = icon
                                Haptics.selection()
                            } label: {
                                IconGlyphCell(icon: icon, isSelected: icon == selection)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(name.split(separator: ".").joined(separator: " "))
                            .accessibilityAddTraits(icon == selection ? AccessibilityTraits.isSelected : AccessibilityTraits())
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Icon")
    }
}

/// One tappable glyph in the picker grid. The selected one is tinted and ringed.
private struct IconGlyphCell: View {
    let icon: ItemIcon
    let isSelected: Bool

    var body: some View {
        ItemIconView(icon: icon, size: 26)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: isSelected ? 2 : 0)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        IconPickerView(selection: .constant(ItemIcon.defaultIcon))
    }
}
