import SwiftData
import SwiftUI

/// One tappable card in the "Your items" grid. Tapping it flies the item into (or out of) the drum.
///
/// The card reports its frame under `FrameKey.card(item.uuid)` so the Load screen knows where
/// a flight starts or lands.
struct ItemCardView: View {
    let item: ClothingItem
    let isInDrum: Bool
    let isInFlight: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            cardContent
        }
        .buttonStyle(.plain)
        .reportFrame(.card(item.uuid))
        .opacity(cardOpacity)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(isInDrum ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    private var cardContent: some View {
        VStack(spacing: 6) {
            ItemIconView(icon: item.icon, size: 34)
            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            HStack(spacing: 4) {
                Circle()
                    .fill(item.colourGroup.swatch)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1))
                    .frame(width: 10, height: 10)
                Text(captionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(cardBackground)
        .overlay(alignment: .topTrailing) {
            if isInDrum {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, Color.accentColor)
                    .padding(6)
            }
        }
    }

    /// The item's tint washed over the grouped background, so dark mode keeps its contrast.
    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(itemTint(hex: item.tintHex, colourGroup: item.colourGroup).opacity(0.22))
        }
    }

    private var cardOpacity: Double {
        if isInFlight { return 0.3 }
        if isInDrum { return 0.55 }
        return 1
    }

    private var captionText: String {
        if item.quantity > 1 {
            return "\(item.fabricWeight.displayName) ×\(item.quantity)"
        }
        return item.fabricWeight.displayName
    }

    private var accessibilityDescription: String {
        let drumState = isInDrum ? "in drum" : "not in drum"
        return "\(item.name), \(item.bleedRisk.displayName.lowercased()) bleed risk, \(item.fabricWeight.displayName.lowercased()), \(drumState)"
    }

    private var accessibilityHintText: String {
        return isInDrum ? "Double tap to take it out of the drum" : "Double tap to add it to the drum"
    }
}
