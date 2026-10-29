import Foundation

/// The six colour families a saved item can belong to.
///
/// Whites and lights are the "receivers" in the bleed rules: dye that travels onto
/// them is visible, so the scoring treats them as the vulnerable side of a pair.
enum ColourGroup: String, CaseIterable, Codable, Identifiable, Sendable {
    case whites
    case lights
    case brights
    case darks
    case reds
    case denim

    var id: String { return rawValue }

    /// Full label used in pickers and the explainer.
    var displayName: String {
        switch self {
        case .whites: return "Whites"
        case .lights: return "Lights / Pastels"
        case .brights: return "Brights"
        case .darks: return "Darks"
        case .reds: return "Reds / Pinks"
        case .denim: return "Denim"
        }
    }

    /// Compact label for cards and chips.
    var shortName: String {
        switch self {
        case .whites: return "Whites"
        case .lights: return "Lights"
        case .brights: return "Brights"
        case .darks: return "Darks"
        case .reds: return "Reds"
        case .denim: return "Denim"
        }
    }

    /// The bleed risk a new item in this group starts with. The user can override it.
    var defaultBleedRisk: BleedRisk {
        switch self {
        case .whites, .lights: return .low
        case .brights, .darks: return .medium
        case .reds, .denim: return .high
        }
    }

    /// Whites and lights show transferred dye most readily.
    var showsBleedEasily: Bool {
        return self == .whites || self == .lights
    }
}
