import Foundation

/// Every number the scoring engine uses, in one place.
///
/// Change a value here (or pass a custom instance to `assessLoad`) to retune the app.
/// The "How scoring works" screen reads its figures from this struct, so it never drifts from the engine.
struct ScoringWeights: Hashable, Sendable {

    // MARK: Colour bleeding (per pair)

    /// A High-bleed item with any Whites or Lights item.
    var highBleedWithWhitesOrLights = 40
    /// A High-bleed item with a Brights item from a different colour group.
    var highBleedWithOtherBrights = 20
    /// A Medium-bleed item with a Whites item.
    var mediumBleedWithWhites = 20
    /// A Medium-bleed item with a Lights item.
    var mediumBleedWithLights = 10
    /// Reds/Pinks with anything that is not Reds/Pinks or Darks. Red dye is the classic culprit.
    var redsExtra = 15
    /// Added to any bleed concern for each "new or never washed" item in the pair.
    var newItemExtra = 10

    // MARK: Fabric thickness and delicacy (per pair)

    var heavyWithDelicate = 35
    var heavyWithLight = 15
    var mediumWithDelicate = 15
    /// A lint shedder with a Darks item or with any Delicate item.
    var lintOnDarksOrDelicates = 15
    /// An item with zips or hooks next to a Delicate item.
    var hardwareWithDelicate = 20
    /// Wool or cashmere with anything Heavy.
    var woolWithHeavy = 15
    /// Athletic/synthetic with a Heavy lint shedder.
    var athleticWithHeavyLint = 10

    // MARK: Single item and whole load

    /// A hand-wash-only item in a load with two or more other items.
    var handWashOnlyInLoad = 25
    /// Added once when the load spans Delicate through Heavy.
    var mixedWeightSpan = 10

    // MARK: Score range and levels

    /// Scores are capped here.
    var maximumScore = 100
    /// Scores at or above this are "Mild caution".
    var mildCautionThreshold = 20
    /// Scores at or above this are "Caution".
    var cautionThreshold = 45
    /// Scores at or above this are "Don't wash together".
    var dontWashThreshold = 70

    static let `default` = ScoringWeights()

    init() {}
}
