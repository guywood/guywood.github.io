import Foundation

/// The complete verdict on a load: score, level, every concern, and a suggested split.
struct LoadAssessment: Hashable, Sendable {
    /// The score after capping, 0...`maximumScore`.
    let score: Int
    /// The score before capping. Useful for tests and for the explainer.
    let uncappedScore: Int
    /// Points contributed by colour-bleeding concerns (uncapped). Drives the porthole tint.
    let bleedPoints: Int
    /// Points contributed by fabric and whole-load concerns (uncapped).
    let fabricPoints: Int
    let level: ConcernLevel
    /// Every concern, worst first.
    let concerns: [Concern]
    /// One line for the label under the gauge: the worst concern, or reassurance.
    let headline: String
    /// Groups the load could be split into so that each group is concern-free.
    /// Empty when the load is fine as it is (or has fewer than two items).
    let suggestedSplit: [[LoadItem]]
    /// The cap the score was clamped to.
    let maximumScore: Int
    /// How many items were assessed.
    let itemCount: Int

    init(
        score: Int,
        uncappedScore: Int,
        bleedPoints: Int,
        fabricPoints: Int,
        level: ConcernLevel,
        concerns: [Concern],
        headline: String,
        suggestedSplit: [[LoadItem]],
        maximumScore: Int,
        itemCount: Int
    ) {
        self.score = score
        self.uncappedScore = uncappedScore
        self.bleedPoints = bleedPoints
        self.fabricPoints = fabricPoints
        self.level = level
        self.concerns = concerns
        self.headline = headline
        self.suggestedSplit = suggestedSplit
        self.maximumScore = maximumScore
        self.itemCount = itemCount
    }

    /// `score / maximumScore`, 0...1. This is what the gauge fills to.
    var fraction: Double {
        guard maximumScore > 0 else { return 0 }
        return min(1, max(0, Double(score) / Double(maximumScore)))
    }

    var isEmptyLoad: Bool { return itemCount == 0 }
    var hasConcerns: Bool { return !concerns.isEmpty }

    /// The worst concern, if any.
    var worstConcern: Concern? { return concerns.first }

    /// The concerns that involve a given item.
    func concerns(involving itemID: UUID) -> [Concern] {
        return concerns.filter { $0.involves(itemID) }
    }

    /// The assessment of an empty drum.
    static let empty = LoadAssessment(
        score: 0,
        uncappedScore: 0,
        bleedPoints: 0,
        fabricPoints: 0,
        level: .safe,
        concerns: [],
        headline: "Tap items to add them to the drum.",
        suggestedSplit: [],
        maximumScore: ScoringWeights.default.maximumScore,
        itemCount: 0
    )
}
