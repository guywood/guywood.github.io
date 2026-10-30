import SwiftUI

/// Explains every scoring rule, the level bands and the split suggestion.
///
/// Every number on this screen is read from the `ScoringWeights` it is given, so the explainer
/// can never drift from the engine. Pass a custom instance to document a retuned app.
struct HowScoringWorksView: View {
    let weights: ScoringWeights

    var body: some View {
        List {
            bleedingSection
            fabricSection
            levelsSection
            splitSection
            notesSection
        }
        .navigationTitle("How scoring works")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var bleedingSection: some View {
        Section {
            ScoringRuleRow(
                text: "A high bleed-risk item with any Whites or Lights item.",
                points: weights.highBleedWithWhitesOrLights
            )
            ScoringRuleRow(
                text: "A high bleed-risk item with a Brights item from another colour group.",
                points: weights.highBleedWithOtherBrights
            )
            ScoringRuleRow(
                text: "A medium bleed-risk item with a Whites item.",
                points: weights.mediumBleedWithWhites
            )
            ScoringRuleRow(
                text: "A medium bleed-risk item with a Lights or Pastels item.",
                points: weights.mediumBleedWithLights
            )
            ScoringRuleRow(
                text: "Reds or Pinks with anything other than Darks.",
                detail: "Added on top of the rules above, or on its own when no other bleed rule fires.",
                points: weights.redsExtra
            )
            ScoringRuleRow(
                text: "Each item in the pair that is new or never washed.",
                detail: "Added to any bleed concern. A new item is also treated as one bleed level riskier.",
                points: weights.newItemExtra
            )
        } header: {
            Text("Colour bleeding")
        } footer: {
            Text("Checked for every pair of items from different colour groups.")
        }
    }

    private var fabricSection: some View {
        Section {
            ScoringRuleRow(
                text: "A Heavy item with a Delicate item.",
                detail: "Abrasion and snagging.",
                points: weights.heavyWithDelicate
            )
            ScoringRuleRow(
                text: "A Heavy item with a Light item.",
                detail: "Rubbing and tangling.",
                points: weights.heavyWithLight
            )
            ScoringRuleRow(
                text: "A Medium item with a Delicate item.",
                points: weights.mediumWithDelicate
            )
            ScoringRuleRow(
                text: "A lint shedder with a Darks item or any Delicate item.",
                points: weights.lintOnDarksOrDelicates
            )
            ScoringRuleRow(
                text: "An item with zips or hooks next to a Delicate item.",
                points: weights.hardwareWithDelicate
            )
            ScoringRuleRow(
                text: "Wool or cashmere with anything Heavy.",
                detail: "Felting from agitation.",
                points: weights.woolWithHeavy
            )
            ScoringRuleRow(
                text: "Athletic or synthetic with a Heavy lint shedder.",
                points: weights.athleticWithHeavyLint
            )
            ScoringRuleRow(
                text: "A hand-wash only item in a load with two or more other items.",
                detail: "Counted once per hand-wash item.",
                points: weights.handWashOnlyInLoad
            )
            ScoringRuleRow(
                text: "The load spans Delicate through Heavy.",
                detail: "Added once for the whole load.",
                points: weights.mixedWeightSpan
            )
        } header: {
            Text("Fabric thickness and delicacy")
        } footer: {
            Text("Fabric weight runs Delicate, Light, Medium, Heavy. Pair rules are checked for every pair of items in the load.")
        }
    }

    private var levelsSection: some View {
        Section {
            ForEach(levelBands) { band in
                LevelBandRow(band: band)
            }
        } header: {
            Text("Levels")
        } footer: {
            Text("A load's score is the total of its concern points. The band is the highest one whose lowest score the total reaches.")
        }
    }

    private var splitSection: some View {
        Section {
            Text("When a load has any concern, Wash Check also suggests how to split it. The items with the most conflicts are placed first. Each item joins the first group it can enter without creating a concern, and a new group is started when none will take it. Groups are shown in the order the items were added.")
                .font(.body)
        } header: {
            Text("Split suggestion")
        }
    }

    private var notesSection: some View {
        Section {
            Text("Items in the same colour group never bleed onto each other.")
            Text("Two lint shedders together, such as towels with towels, are fine.")
            Text("Quantity does not change the score. Several of the same item count the same as one.")
            Text("The score is capped at \(weights.maximumScore).")
            Text("A rule whose points are set to zero is switched off.")
        } header: {
            Text("Notes")
        }
    }

    // MARK: - Level bands

    /// The four bands with their inclusive score ranges, derived from the thresholds and the cap.
    private var levelBands: [LevelBand] {
        let levels: [ConcernLevel] = ConcernLevel.allCases
        var bands: [LevelBand] = []
        for (index, level) in levels.enumerated() {
            let lower: Int = level.lowerBound(weights: weights)
            let nextIndex: Int = index + 1
            let upper: Int
            if nextIndex < levels.count {
                upper = max(lower, levels[nextIndex].lowerBound(weights: weights) - 1)
            } else {
                upper = max(lower, weights.maximumScore)
            }
            bands.append(LevelBand(level: level, lower: lower, upper: upper))
        }
        return bands
    }
}

// MARK: - Rows

/// One rule: its description, an optional note, and the points it adds.
private struct ScoringRuleRow: View {
    let text: String
    let detail: String?
    let points: Int

    init(text: String, detail: String? = nil, points: Int) {
        self.text = text
        self.detail = detail
        self.points = points
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.body)
                if let detail = detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text("+\(points)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(points) points")
        }
        .accessibilityElement(children: .combine)
    }
}

/// One band of the "Levels" section and the inclusive score range that maps to it.
private struct LevelBand: Identifiable {
    let level: ConcernLevel
    let lower: Int
    let upper: Int

    var id: Int { return level.rawValue }
}

/// A level band: colour dot, name, advice and score range.
private struct LevelBandRow: View {
    let band: LevelBand

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(GaugePalette.color(for: band.level))
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(band.level.displayName)
                    .font(.body)
                Text(band.level.advice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text("\(band.lower)–\(band.upper)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(band.lower) to \(band.upper) points")
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        HowScoringWorksView(weights: .default)
    }
}
