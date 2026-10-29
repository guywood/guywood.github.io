import Foundation

/// Scores a load. Pure and synchronous: the same items always give the same assessment.
///
/// Usage: `assessLoad(items)` or `LoadAssessor(weights: custom).assess(items)`.
func assessLoad(_ items: [LoadItem], weights: ScoringWeights = .default) -> LoadAssessment {
    return LoadAssessor(weights: weights).assess(items)
}

struct LoadAssessor: Sendable {
    let weights: ScoringWeights

    init(weights: ScoringWeights = .default) {
        self.weights = weights
    }

    /// Assesses a load. `includeSplit` is turned off internally while computing the split itself.
    func assess(_ items: [LoadItem], includeSplit: Bool = true) -> LoadAssessment {
        var concerns: [Concern] = []

        // Every unordered pair of distinct items.
        for i in items.indices {
            for j in items.indices where j > i {
                concerns.append(contentsOf: pairConcerns(items[i], items[j]))
            }
        }

        // Single-item rules.
        for item in items {
            concerns.append(contentsOf: singleItemConcerns(item, in: items))
        }

        // Whole-load rules.
        concerns.append(contentsOf: wholeLoadConcerns(items))

        // A rule whose weight is set to zero is disabled.
        concerns.removeAll { $0.points <= 0 }
        concerns.sort(by: LoadAssessor.worstFirst)

        let bleedPoints = concerns.filter { $0.kind == .colourBleeding }.reduce(0) { $0 + $1.points }
        let fabricPoints = concerns.filter { $0.kind != .colourBleeding }.reduce(0) { $0 + $1.points }
        let uncapped = bleedPoints + fabricPoints
        let score = min(weights.maximumScore, max(0, uncapped))
        let level = ConcernLevel.level(for: score, weights: weights)

        let split: [[LoadItem]]
        if includeSplit && !concerns.isEmpty {
            split = LoadSplitter(assessor: self).split(items)
        } else {
            split = []
        }

        return LoadAssessment(
            score: score,
            uncappedScore: uncapped,
            bleedPoints: bleedPoints,
            fabricPoints: fabricPoints,
            level: level,
            concerns: concerns,
            headline: headline(for: items, concerns: concerns, level: level),
            suggestedSplit: split,
            maximumScore: weights.maximumScore,
            itemCount: items.count
        )
    }

    // MARK: - Pair rules

    /// Every concern raised by one unordered pair. Zero-point (disabled) rules are omitted.
    func pairConcerns(_ a: LoadItem, _ b: LoadItem) -> [Concern] {
        var result: [Concern] = []
        result.append(contentsOf: bleedConcerns(from: a, onto: b))
        result.append(contentsOf: bleedConcerns(from: b, onto: a))
        result.append(contentsOf: fabricConcerns(a, b))
        return result.filter { $0.points > 0 }
    }

    /// Dye travelling from `source` onto `target`. Same-group pairs never bleed.
    func bleedConcerns(from source: LoadItem, onto target: LoadItem) -> [Concern] {
        guard source.colourGroup != target.colourGroup else { return [] }

        var points = 0
        var severity: ConcernSeverity? = nil
        var message = ""
        var notes: [String] = []

        switch source.effectiveBleedRisk {
        case .high:
            if target.colourGroup.showsBleedEasily {
                points += weights.highBleedWithWhitesOrLights
                severity = .high
                message = "\(source.name) may bleed onto \(target.name)."
                notes.append("High bleed risk next to whites or lights (+\(weights.highBleedWithWhitesOrLights)).")
            } else if target.colourGroup == .brights {
                points += weights.highBleedWithOtherBrights
                severity = .medium
                message = "\(source.name) could tint \(target.name)."
                notes.append("High bleed risk with other bright colours (+\(weights.highBleedWithOtherBrights)).")
            }
        case .medium:
            if target.colourGroup == .whites {
                points += weights.mediumBleedWithWhites
                severity = .medium
                message = "\(source.name) might bleed onto \(target.name)."
                notes.append("Medium bleed risk with whites (+\(weights.mediumBleedWithWhites)).")
            } else if target.colourGroup == .lights {
                points += weights.mediumBleedWithLights
                severity = .low
                message = "\(source.name) might slightly tint \(target.name)."
                notes.append("Medium bleed risk with lights and pastels (+\(weights.mediumBleedWithLights)).")
            }
        case .low:
            break
        }

        // Red and pink dye is the classic culprit. The same-group guard above already
        // excludes reds-with-reds, so only darks are exempt here.
        if source.colourGroup == .reds && target.colourGroup != .darks {
            points += weights.redsExtra
            if severity == nil {
                severity = .low
                message = "\(source.name) is red or pink, the classic dye culprit, next to \(target.name)."
            }
            notes.append("Red and pink dyes are the classic culprits (+\(weights.redsExtra)).")
        }

        guard let resolvedSeverity = severity, points > 0 else { return [] }

        if source.isNew {
            points += weights.newItemExtra
            notes.append("\(source.name) is new or never washed (+\(weights.newItemExtra)).")
        }
        if target.isNew {
            points += weights.newItemExtra
            notes.append("\(target.name) is new or never washed (+\(weights.newItemExtra)).")
        }

        return [Concern(
            id: "bleed:\(source.id.uuidString):\(target.id.uuidString)",
            kind: .colourBleeding,
            severity: resolvedSeverity,
            points: points,
            itemIDs: [source.id, target.id],
            message: message,
            detail: notes.joined(separator: " ")
        )]
    }

    /// Thickness, delicacy, lint, hardware, wool and synthetic rules for one unordered pair.
    func fabricConcerns(_ a: LoadItem, _ b: LoadItem) -> [Concern] {
        var result: [Concern] = []

        let heavier = a.fabricWeight >= b.fabricWeight ? a : b
        let lighter = a.fabricWeight >= b.fabricWeight ? b : a
        let pairKey = "\(heavier.id.uuidString):\(lighter.id.uuidString)"

        switch (heavier.fabricWeight, lighter.fabricWeight) {
        case (.heavy, .delicate):
            result.append(Concern(
                id: "weight:" + pairKey,
                kind: .fabric,
                severity: .high,
                points: weights.heavyWithDelicate,
                itemIDs: [heavier.id, lighter.id],
                message: "\(heavier.name) will abrade and snag \(lighter.name).",
                detail: "Heavy items tumbling against delicates cause abrasion and snagging (+\(weights.heavyWithDelicate))."
            ))
        case (.heavy, .light):
            result.append(Concern(
                id: "weight:" + pairKey,
                kind: .fabric,
                severity: .medium,
                points: weights.heavyWithLight,
                itemIDs: [heavier.id, lighter.id],
                message: "\(heavier.name) is much heavier than \(lighter.name) and will rub and tangle it.",
                detail: "Heavy with light (+\(weights.heavyWithLight))."
            ))
        case (.medium, .delicate):
            result.append(Concern(
                id: "weight:" + pairKey,
                kind: .fabric,
                severity: .medium,
                points: weights.mediumWithDelicate,
                itemIDs: [heavier.id, lighter.id],
                message: "\(heavier.name) is heavier than \(lighter.name) and may rub it.",
                detail: "Medium with delicate (+\(weights.mediumWithDelicate))."
            ))
        default:
            break
        }

        result.append(contentsOf: lintConcern(from: a, onto: b))
        result.append(contentsOf: lintConcern(from: b, onto: a))
        result.append(contentsOf: hardwareConcern(from: a, onto: b))
        result.append(contentsOf: hardwareConcern(from: b, onto: a))
        result.append(contentsOf: woolConcern(a, b))
        result.append(contentsOf: athleticConcern(a, b))

        return result
    }

    /// Lint shed by `source` onto a dark or delicate `target`.
    /// Two shedders together (towels with towels) are not a concern.
    private func lintConcern(from source: LoadItem, onto target: LoadItem) -> [Concern] {
        guard source.isLintShedder, !target.isLintShedder else { return [] }
        let targetIsDark = target.colourGroup == .darks
        let targetIsDelicate = target.fabricWeight == .delicate
        guard targetIsDark || targetIsDelicate else { return [] }

        let message: String
        if targetIsDelicate {
            message = "\(source.name) will shed lint that clings to \(target.name)."
        } else {
            message = "\(source.name) will shed lint that shows on \(target.name)."
        }
        return [Concern(
            id: "lint:\(source.id.uuidString):\(target.id.uuidString)",
            kind: .fabric,
            severity: .medium,
            points: weights.lintOnDarksOrDelicates,
            itemIDs: [source.id, target.id],
            message: message,
            detail: "Lint shedders next to darks or delicates (+\(weights.lintOnDarksOrDelicates))."
        )]
    }

    /// Zips and hooks on `source` next to a delicate `target`.
    private func hardwareConcern(from source: LoadItem, onto target: LoadItem) -> [Concern] {
        guard source.hasHardware, target.fabricWeight == .delicate else { return [] }
        return [Concern(
            id: "hardware:\(source.id.uuidString):\(target.id.uuidString)",
            kind: .fabric,
            severity: .high,
            points: weights.hardwareWithDelicate,
            itemIDs: [source.id, target.id],
            message: "Zips or hooks on \(source.name) can snag \(target.name).",
            detail: "Hardware next to a delicate item (+\(weights.hardwareWithDelicate))."
        )]
    }

    /// Wool or cashmere felting against anything heavy. At most one concern per pair.
    private func woolConcern(_ a: LoadItem, _ b: LoadItem) -> [Concern] {
        let candidates: [(wool: LoadItem, other: LoadItem)] = [(a, b), (b, a)]
        for candidate in candidates where candidate.wool.isWoolOrCashmere && candidate.other.fabricWeight == .heavy {
            return [Concern(
                id: "wool:\(candidate.wool.id.uuidString):\(candidate.other.id.uuidString)",
                kind: .fabric,
                severity: .medium,
                points: weights.woolWithHeavy,
                itemIDs: [candidate.wool.id, candidate.other.id],
                message: "\(candidate.wool.name) can felt from agitation against \(candidate.other.name).",
                detail: "Wool or cashmere with anything heavy (+\(weights.woolWithHeavy))."
            )]
        }
        return []
    }

    /// Synthetic sportswear trapping lint from a heavy shedder. At most one concern per pair.
    private func athleticConcern(_ a: LoadItem, _ b: LoadItem) -> [Concern] {
        let candidates: [(athletic: LoadItem, shedder: LoadItem)] = [(a, b), (b, a)]
        for candidate in candidates where candidate.athletic.isAthletic && candidate.shedder.isLintShedder && candidate.shedder.fabricWeight == .heavy {
            return [Concern(
                id: "athletic:\(candidate.athletic.id.uuidString):\(candidate.shedder.id.uuidString)",
                kind: .fabric,
                severity: .low,
                points: weights.athleticWithHeavyLint,
                itemIDs: [candidate.athletic.id, candidate.shedder.id],
                message: "Lint from \(candidate.shedder.name) will trap in the synthetic fibres of \(candidate.athletic.name).",
                detail: "Athletic or synthetic with a heavy lint shedder (+\(weights.athleticWithHeavyLint))."
            )]
        }
        return []
    }

    // MARK: - Single-item rules

    func singleItemConcerns(_ item: LoadItem, in items: [LoadItem]) -> [Concern] {
        let otherCount = items.filter { $0.id != item.id }.count
        guard item.isHandWashOnly, otherCount >= 2 else { return [] }
        return [Concern(
            id: "handwash:\(item.id.uuidString)",
            kind: .fabric,
            severity: .high,
            points: weights.handWashOnlyInLoad,
            itemIDs: [item.id],
            message: "\(item.name) is hand-wash only and shouldn't go in a machine load with other items.",
            detail: "Hand-wash only in a load of two or more other items (+\(weights.handWashOnlyInLoad))."
        )]
    }

    // MARK: - Whole-load rules

    func wholeLoadConcerns(_ items: [LoadItem]) -> [Concern] {
        let present = Set(items.map { $0.fabricWeight })
        guard present.contains(.delicate), present.contains(.heavy) else { return [] }
        return [Concern(
            id: "span",
            kind: .wholeLoad,
            severity: .low,
            points: weights.mixedWeightSpan,
            itemIDs: [],
            message: "Very mixed load: delicates and heavy items spin and dry differently.",
            detail: "The load spans Delicate through Heavy (+\(weights.mixedWeightSpan))."
        )]
    }

    // MARK: - Helpers

    private func headline(for items: [LoadItem], concerns: [Concern], level: ConcernLevel) -> String {
        if items.isEmpty {
            return LoadAssessment.empty.headline
        }
        if let worst = concerns.first {
            return worst.message
        }
        if items.count == 1 {
            return "One item, nothing to clash with."
        }
        return level.advice
    }

    /// Severity first, then points, then message, so ordering is deterministic.
    static func worstFirst(_ lhs: Concern, _ rhs: Concern) -> Bool {
        if lhs.severity != rhs.severity { return lhs.severity > rhs.severity }
        if lhs.points != rhs.points { return lhs.points > rhs.points }
        if lhs.message != rhs.message { return lhs.message < rhs.message }
        return lhs.id < rhs.id
    }
}
