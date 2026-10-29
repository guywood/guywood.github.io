import Foundation

/// How serious a single concern is. Drives ordering and the icon colour in the "Why?" list.
enum ConcernSeverity: Int, CaseIterable, Comparable, Sendable {
    case low = 0
    case medium = 1
    case high = 2

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    static func < (lhs: ConcernSeverity, rhs: ConcernSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Which family of rule produced a concern.
enum ConcernKind: String, CaseIterable, Sendable {
    case colourBleeding
    case fabric
    case wholeLoad

    var displayName: String {
        switch self {
        case .colourBleeding: return "Colour bleeding"
        case .fabric: return "Fabric"
        case .wholeLoad: return "Whole load"
        }
    }
}

/// One flagged problem with the load: a risky pair, a single item that should not be there,
/// or a property of the whole load.
struct Concern: Identifiable, Hashable, Sendable {
    /// Stable identifier built from the rule and the items involved, so lists animate sensibly.
    let id: String
    let kind: ConcernKind
    let severity: ConcernSeverity
    /// Points this concern contributes to the (uncapped) score.
    let points: Int
    /// The one or two items involved, in the order they appear in `message`.
    let itemIDs: [UUID]
    /// Plain-language headline, e.g. "Red hoodie may bleed onto White t-shirts."
    let message: String
    /// Secondary explanation of the rule(s) that fired.
    let detail: String

    init(id: String, kind: ConcernKind, severity: ConcernSeverity, points: Int, itemIDs: [UUID], message: String, detail: String) {
        self.id = id
        self.kind = kind
        self.severity = severity
        self.points = points
        self.itemIDs = itemIDs
        self.message = message
        self.detail = detail
    }

    /// Whether the concern involves this item.
    func involves(_ itemID: UUID) -> Bool {
        return itemIDs.contains(itemID)
    }
}
