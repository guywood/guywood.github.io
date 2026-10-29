import SwiftUI
import UIKit

extension ColourGroup {
    /// The representative swatch for the group, used for dots, pickers and default card tints.
    var swatch: Color {
        switch self {
        case .whites: return Color(red: 0.96, green: 0.96, blue: 0.94)
        case .lights: return Color(red: 0.80, green: 0.89, blue: 0.95)
        case .brights: return Color(red: 1.00, green: 0.69, blue: 0.13)
        case .darks: return Color(red: 0.23, green: 0.23, blue: 0.29)
        case .reds: return Color(red: 0.88, green: 0.20, blue: 0.30)
        case .denim: return Color(red: 0.24, green: 0.35, blue: 0.60)
        }
    }
}

extension FabricWeight {
    /// SF Symbol used next to the weight in cards and pickers.
    var symbolName: String {
        switch self {
        case .delicate: return "wind"
        case .light: return "cloud"
        case .medium: return "square.stack"
        case .heavy: return "scalemass"
        }
    }
}

extension BleedRisk {
    /// SF Symbol used next to the risk in cards and pickers.
    var symbolName: String {
        switch self {
        case .low: return "drop"
        case .medium: return "drop.halffull"
        case .high: return "drop.fill"
        }
    }
}

extension ConcernSeverity {
    /// Colour of the severity dot in the "Why?" list.
    var color: Color {
        switch self {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        }
    }
}

extension Color {
    /// Parses `#RRGGBB` or `RRGGBB`. Returns `nil` for anything else.
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    /// `#RRGGBB` for this colour in sRGB, or `nil` if it cannot be resolved.
    var hexString: String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        let r = UInt32(max(0, min(255, (red * 255).rounded())))
        let g = UInt32(max(0, min(255, (green * 255).rounded())))
        let b = UInt32(max(0, min(255, (blue * 255).rounded())))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

/// The tint to paint an item's card and drum chip with: the saved hex, or the group's swatch.
func itemTint(hex: String?, colourGroup: ColourGroup) -> Color {
    if let hex = hex, let color = Color(hex: hex) {
        return color
    }
    return colourGroup.swatch
}
