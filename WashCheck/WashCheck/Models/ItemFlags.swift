import Foundation

/// Optional, multi-select attributes that unlock extra scoring rules.
struct ItemFlags: OptionSet, Hashable, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Towels, fleece, new flannel: sheds fibres onto everything else.
    static let lintShedder = ItemFlags(rawValue: 1 << 0)
    /// Zips, hooks, buckles, metal buttons.
    static let hasHardware = ItemFlags(rawValue: 1 << 1)
    /// Wool or cashmere knits that can felt with agitation.
    static let woolOrCashmere = ItemFlags(rawValue: 1 << 2)
    /// Synthetic sportswear that traps lint and holds odour.
    static let athletic = ItemFlags(rawValue: 1 << 3)
    /// Should not be machine washed with a full load at all.
    static let handWashOnly = ItemFlags(rawValue: 1 << 4)

    /// Every individual flag, in display order.
    static let allFlags: [ItemFlags] = [.lintShedder, .hasHardware, .woolOrCashmere, .athletic, .handWashOnly]

    /// Human label. For a combined set this is a comma-separated list.
    var displayName: String {
        switch self {
        case .lintShedder: return "Lint shedder"
        case .hasHardware: return "Has hardware"
        case .woolOrCashmere: return "Wool / cashmere"
        case .athletic: return "Athletic / synthetic"
        case .handWashOnly: return "Hand-wash only"
        default:
            return ItemFlags.allFlags
                .filter { self.contains($0) }
                .map { $0.displayName }
                .joined(separator: ", ")
        }
    }

    /// Short explanation shown under the toggle in the editor.
    var detail: String {
        switch self {
        case .lintShedder: return "Towels, fleece, flannel"
        case .hasHardware: return "Zips, hooks, buckles"
        case .woolOrCashmere: return "Can felt when agitated"
        case .athletic: return "Synthetic sportswear"
        case .handWashOnly: return "Not for a full machine load"
        default: return ""
        }
    }

    /// SF Symbol used next to the flag in pickers and lists.
    var symbolName: String {
        switch self {
        case .lintShedder: return "sparkles"
        case .hasHardware: return "paperclip"
        case .woolOrCashmere: return "scribble.variable"
        case .athletic: return "figure.run"
        case .handWashOnly: return "hand.raised"
        default: return "tag"
        }
    }

    /// The individual flags contained in this set, in display order.
    var elements: [ItemFlags] {
        return ItemFlags.allFlags.filter { self.contains($0) }
    }
}
