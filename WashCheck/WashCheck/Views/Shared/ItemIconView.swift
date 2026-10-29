import SwiftUI

/// Renders an `ItemIcon` (emoji or SF Symbol) at a given point size.
struct ItemIconView: View {
    let icon: ItemIcon
    var size: CGFloat = 32

    var body: some View {
        Group {
            switch icon {
            case .emoji(let value):
                Text(value)
                    .font(.system(size: size))
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: size * 0.85, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: size * 1.3, height: size * 1.3)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ItemIconView(icon: .emoji("👕"))
        ItemIconView(icon: .symbol("hanger"))
        ItemIconView(icon: .emoji("🧦"), size: 48)
    }
    .padding()
}
