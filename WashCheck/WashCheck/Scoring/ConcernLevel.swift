import Foundation

/// The four bands the gauge snaps its label to.
enum ConcernLevel: Int, CaseIterable, Comparable, Sendable {
    case safe = 0
    case mildCaution = 1
    case caution = 2
    case dontWashTogether = 3

    var displayName: String {
        switch self {
        case .safe: return "Safe"
        case .mildCaution: return "Mild caution"
        case .caution: return "Caution"
        case .dontWashTogether: return "Don't wash together"
        }
    }

    /// Very short label for tick marks on the gauge.
    var shortName: String {
        switch self {
        case .safe: return "Safe"
        case .mildCaution: return "Mild"
        case .caution: return "Caution"
        case .dontWashTogether: return "Don't"
        }
    }

    /// One-line advice shown when no concern message is more specific.
    var advice: String {
        switch self {
        case .safe: return "Nothing here should bleed, snag, or shed."
        case .mildCaution: return "Probably fine, but keep an eye on the flagged pairs."
        case .caution: return "Consider splitting this load."
        case .dontWashTogether: return "Split this load before you run it."
        }
    }

    /// Maps a (capped) score onto a level using the configured thresholds.
    static func level(for score: Int, weights: ScoringWeights = .default) -> ConcernLevel {
        if score >= weights.dontWashThreshold { return .dontWashTogether }
        if score >= weights.cautionThreshold { return .caution }
        if score >= weights.mildCautionThreshold { return .mildCaution }
        return .safe
    }

    /// The lowest score that maps to this level.
    func lowerBound(weights: ScoringWeights = .default) -> Int {
        switch self {
        case .safe: return 0
        case .mildCaution: return weights.mildCautionThreshold
        case .caution: return weights.cautionThreshold
        case .dontWashTogether: return weights.dontWashThreshold
        }
    }

    static func < (lhs: ConcernLevel, rhs: ConcernLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
