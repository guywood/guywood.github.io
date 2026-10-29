import Foundation

/// A plain, value-typed snapshot of a clothing item. This is what the scoring engine consumes.
///
/// `ClothingItem` (the SwiftData model) converts itself into one of these so that
/// `assessLoad` stays pure, synchronous and trivially unit-testable.
struct LoadItem: Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var colourGroup: ColourGroup
    /// The bleed risk as set by the user, before the "new or never washed" bump.
    var bleedRisk: BleedRisk
    var isNew: Bool
    var fabricWeight: FabricWeight
    var flags: ItemFlags
    /// How many of this item are in the load. Shown on chips; it does not change the score.
    var quantity: Int

    init(
        id: UUID = UUID(),
        name: String,
        colourGroup: ColourGroup,
        bleedRisk: BleedRisk? = nil,
        isNew: Bool = false,
        fabricWeight: FabricWeight,
        flags: ItemFlags = [],
        quantity: Int = 1
    ) {
        self.id = id
        self.name = name
        self.colourGroup = colourGroup
        self.bleedRisk = bleedRisk ?? colourGroup.defaultBleedRisk
        self.isNew = isNew
        self.fabricWeight = fabricWeight
        self.flags = flags
        self.quantity = max(1, quantity)
    }

    /// The risk the scoring rules actually use: new items are bumped up one level.
    var effectiveBleedRisk: BleedRisk {
        return isNew ? bleedRisk.bumpedUp : bleedRisk
    }

    var isLintShedder: Bool { return flags.contains(.lintShedder) }
    var hasHardware: Bool { return flags.contains(.hasHardware) }
    var isWoolOrCashmere: Bool { return flags.contains(.woolOrCashmere) }
    var isAthletic: Bool { return flags.contains(.athletic) }
    var isHandWashOnly: Bool { return flags.contains(.handWashOnly) }
}
