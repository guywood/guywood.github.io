import Foundation

/// A starter item definition. Plain data so it can be shared by the seeding code and the tests.
struct StarterItem: Hashable, Sendable {
    let name: String
    let icon: ItemIcon
    let colourGroup: ColourGroup
    /// `nil` means "use the colour group's default".
    let bleedRisk: BleedRisk?
    let isNew: Bool
    let fabricWeight: FabricWeight
    let flags: ItemFlags
    let quantity: Int
    /// Card tint as `#RRGGBB`.
    let tintHex: String

    init(
        name: String,
        icon: ItemIcon,
        colourGroup: ColourGroup,
        bleedRisk: BleedRisk? = nil,
        isNew: Bool = false,
        fabricWeight: FabricWeight,
        flags: ItemFlags = [],
        quantity: Int = 1,
        tintHex: String
    ) {
        self.name = name
        self.icon = icon
        self.colourGroup = colourGroup
        self.bleedRisk = bleedRisk
        self.isNew = isNew
        self.fabricWeight = fabricWeight
        self.flags = flags
        self.quantity = quantity
        self.tintHex = tintHex
    }

    /// The scoring snapshot for this starter, with a fresh identifier.
    func makeLoadItem(id: UUID = UUID()) -> LoadItem {
        return LoadItem(
            id: id,
            name: name,
            colourGroup: colourGroup,
            bleedRisk: bleedRisk,
            isNew: isNew,
            fabricWeight: fabricWeight,
            flags: flags,
            quantity: quantity
        )
    }
}

/// The dozen items a fresh install starts with. Users can edit or delete every one of them.
enum StarterItems {
    static let all: [StarterItem] = [
        StarterItem(name: "White t-shirts", icon: .emoji("👕"), colourGroup: .whites, fabricWeight: .light, quantity: 3, tintHex: "#F4F4F0"),
        StarterItem(name: "White sheets", icon: .emoji("🛏️"), colourGroup: .whites, fabricWeight: .medium, tintHex: "#EDEDF5"),
        StarterItem(name: "Bath towels", icon: .emoji("🛁"), colourGroup: .whites, fabricWeight: .heavy, flags: [.lintShedder], quantity: 2, tintHex: "#DCEFF7"),
        StarterItem(name: "Lace underwear", icon: .emoji("🩲"), colourGroup: .lights, fabricWeight: .delicate, quantity: 2, tintHex: "#F7DDE8"),
        StarterItem(name: "Silk scarf", icon: .emoji("🧣"), colourGroup: .brights, fabricWeight: .delicate, flags: [.handWashOnly], tintHex: "#FFD6A5"),
        StarterItem(name: "Gym kit", icon: .emoji("🏃"), colourGroup: .brights, fabricWeight: .light, flags: [.athletic], tintHex: "#CFF5D2"),
        StarterItem(name: "Navy jeans", icon: .emoji("👖"), colourGroup: .denim, fabricWeight: .medium, flags: [.hasHardware], tintHex: "#C5D3EE"),
        StarterItem(name: "Denim jacket", icon: .symbol("hanger"), colourGroup: .denim, isNew: true, fabricWeight: .heavy, flags: [.hasHardware], tintHex: "#B9C9E8"),
        StarterItem(name: "Red hoodie", icon: .emoji("🧥"), colourGroup: .reds, fabricWeight: .heavy, tintHex: "#F8C4C4"),
        StarterItem(name: "Black socks", icon: .emoji("🧦"), colourGroup: .darks, fabricWeight: .light, quantity: 6, tintHex: "#D5D5DC"),
        StarterItem(name: "Wool jumper", icon: .emoji("🧶"), colourGroup: .darks, fabricWeight: .medium, flags: [.woolOrCashmere], tintHex: "#E2D6C8"),
        StarterItem(name: "Fleece throw", icon: .emoji("🛋️"), colourGroup: .darks, fabricWeight: .heavy, flags: [.lintShedder], tintHex: "#D9D2E9"),
    ]
}
