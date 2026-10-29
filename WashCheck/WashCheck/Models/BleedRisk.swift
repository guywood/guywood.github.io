import Foundation

/// How likely an item is to release dye in the wash.
enum BleedRisk: Int, CaseIterable, Codable, Comparable, Identifiable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { return rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    /// One step riskier, saturating at `.high`. Used for "new or never washed" items.
    var bumpedUp: BleedRisk {
        return BleedRisk(rawValue: rawValue + 1) ?? .high
    }

    static func < (lhs: BleedRisk, rhs: BleedRisk) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
