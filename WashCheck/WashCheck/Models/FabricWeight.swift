import Foundation

/// How thick, heavy and robust an item is. Drives the abrasion and tangling rules.
enum FabricWeight: Int, CaseIterable, Codable, Comparable, Identifiable, Sendable {
    case delicate = 0
    case light = 1
    case medium = 2
    case heavy = 3

    var id: Int { return rawValue }

    var displayName: String {
        switch self {
        case .delicate: return "Delicate"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }

    /// Example garments shown in the picker.
    var examples: String {
        switch self {
        case .delicate: return "Silk, lace, lingerie, fine knits"
        case .light: return "T-shirts, blouses, underwear"
        case .medium: return "Jeans, sweatshirts, sheets"
        case .heavy: return "Towels, bath mats, denim jackets, hoodies"
        }
    }

    static func < (lhs: FabricWeight, rhs: FabricWeight) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
