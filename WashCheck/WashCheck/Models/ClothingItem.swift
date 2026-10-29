import Foundation
import SwiftData

/// A saved, reusable clothing item. Persisted with SwiftData.
///
/// Enum-typed attributes are stored as raw values (`colourGroupRaw`, `bleedRiskRaw`, ...)
/// so the schema stays simple and predicate-friendly; the typed accessors wrap them.
@Model
final class ClothingItem {
    @Attribute(.unique) var uuid: UUID
    var name: String
    var iconStorage: String
    var colourGroupRaw: String
    var bleedRiskRaw: Int
    var isNew: Bool
    var fabricWeightRaw: Int
    var flagsRaw: Int
    var quantity: Int
    /// Optional card tint as `#RRGGBB`. When `nil` the colour group's swatch is used.
    var tintHex: String?
    var sortOrder: Int
    /// Whether the item is currently in the washing machine drum. This is how the most recent load persists.
    var isInDrum: Bool
    var createdAt: Date

    init(
        uuid: UUID = UUID(),
        name: String,
        icon: ItemIcon = ItemIcon.defaultIcon,
        colourGroup: ColourGroup,
        bleedRisk: BleedRisk? = nil,
        isNew: Bool = false,
        fabricWeight: FabricWeight,
        flags: ItemFlags = [],
        quantity: Int = 1,
        tintHex: String? = nil,
        sortOrder: Int = 0,
        isInDrum: Bool = false,
        createdAt: Date = Date()
    ) {
        self.uuid = uuid
        self.name = name
        self.iconStorage = icon.storageValue
        self.colourGroupRaw = colourGroup.rawValue
        self.bleedRiskRaw = (bleedRisk ?? colourGroup.defaultBleedRisk).rawValue
        self.isNew = isNew
        self.fabricWeightRaw = fabricWeight.rawValue
        self.flagsRaw = flags.rawValue
        self.quantity = max(1, quantity)
        self.tintHex = tintHex
        self.sortOrder = sortOrder
        self.isInDrum = isInDrum
        self.createdAt = createdAt
    }

    // MARK: - Typed accessors

    var icon: ItemIcon {
        get { return ItemIcon(storageValue: iconStorage) }
        set { iconStorage = newValue.storageValue }
    }

    var colourGroup: ColourGroup {
        get { return ColourGroup(rawValue: colourGroupRaw) ?? .darks }
        set { colourGroupRaw = newValue.rawValue }
    }

    var bleedRisk: BleedRisk {
        get { return BleedRisk(rawValue: bleedRiskRaw) ?? .medium }
        set { bleedRiskRaw = newValue.rawValue }
    }

    var fabricWeight: FabricWeight {
        get { return FabricWeight(rawValue: fabricWeightRaw) ?? .medium }
        set { fabricWeightRaw = newValue.rawValue }
    }

    var flags: ItemFlags {
        get { return ItemFlags(rawValue: flagsRaw) }
        set { flagsRaw = newValue.rawValue }
    }

    /// The value-typed snapshot the scoring engine consumes.
    var loadItem: LoadItem {
        return LoadItem(
            id: uuid,
            name: name,
            colourGroup: colourGroup,
            bleedRisk: bleedRisk,
            isNew: isNew,
            fabricWeight: fabricWeight,
            flags: flags,
            quantity: quantity
        )
    }

    /// Builds a persisted item from a starter definition.
    convenience init(starter: StarterItem, sortOrder: Int) {
        self.init(
            name: starter.name,
            icon: starter.icon,
            colourGroup: starter.colourGroup,
            bleedRisk: starter.bleedRisk,
            isNew: starter.isNew,
            fabricWeight: starter.fabricWeight,
            flags: starter.flags,
            quantity: starter.quantity,
            tintHex: starter.tintHex,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Seeding and resetting

extension ClothingItem {
    /// Inserts the starter items when the store is empty (first launch).
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<ClothingItem>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }
        insertStarters(into: context)
    }

    /// Deletes every saved item and re-inserts the starters. Used by Settings → Reset.
    static func resetToStarters(in context: ModelContext) {
        let descriptor = FetchDescriptor<ClothingItem>()
        if let items = try? context.fetch(descriptor) {
            for item in items {
                context.delete(item)
            }
        }
        insertStarters(into: context)
    }

    private static func insertStarters(into context: ModelContext) {
        for (index, starter) in StarterItems.all.enumerated() {
            context.insert(ClothingItem(starter: starter, sortOrder: index))
        }
        try? context.save()
    }
}
