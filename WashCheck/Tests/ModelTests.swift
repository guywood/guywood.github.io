import XCTest
@testable import WashCheck

final class ModelTests: XCTestCase {

    func testDefaultBleedRiskByColourGroup() {
        XCTAssertEqual(ColourGroup.whites.defaultBleedRisk, .low)
        XCTAssertEqual(ColourGroup.lights.defaultBleedRisk, .low)
        XCTAssertEqual(ColourGroup.brights.defaultBleedRisk, .medium)
        XCTAssertEqual(ColourGroup.darks.defaultBleedRisk, .medium)
        XCTAssertEqual(ColourGroup.reds.defaultBleedRisk, .high)
        XCTAssertEqual(ColourGroup.denim.defaultBleedRisk, .high)
    }

    func testLoadItemUsesGroupDefaultWhenRiskIsNil() {
        let item = LoadItem(name: "Jeans", colourGroup: .denim, fabricWeight: .medium)
        XCTAssertEqual(item.bleedRisk, .high)
        let overridden = LoadItem(name: "Old jeans", colourGroup: .denim, bleedRisk: .low, fabricWeight: .medium)
        XCTAssertEqual(overridden.bleedRisk, .low)
    }

    func testQuantityIsNeverBelowOne() {
        let item = LoadItem(name: "Socks", colourGroup: .darks, fabricWeight: .light, quantity: 0)
        XCTAssertEqual(item.quantity, 1)
    }

    func testBleedRiskBump() {
        XCTAssertEqual(BleedRisk.low.bumpedUp, .medium)
        XCTAssertEqual(BleedRisk.medium.bumpedUp, .high)
        XCTAssertEqual(BleedRisk.high.bumpedUp, .high)
    }

    func testFabricWeightOrdering() {
        XCTAssertLessThan(FabricWeight.delicate, .light)
        XCTAssertLessThan(FabricWeight.light, .medium)
        XCTAssertLessThan(FabricWeight.medium, .heavy)
    }

    func testItemFlagsNamesAndElements() {
        let flags: ItemFlags = [.lintShedder, .handWashOnly]
        XCTAssertEqual(flags.elements, [.lintShedder, .handWashOnly])
        XCTAssertEqual(flags.displayName, "Lint shedder, Hand-wash only")
        XCTAssertEqual(ItemFlags.woolOrCashmere.displayName, "Wool / cashmere")
        XCTAssertEqual(ItemFlags.allFlags.count, 5)
        XCTAssertEqual(ItemFlags().displayName, "")
    }

    func testItemIconRoundTrip() {
        let emoji = ItemIcon.emoji("👖")
        XCTAssertEqual(ItemIcon(storageValue: emoji.storageValue), emoji)
        let symbol = ItemIcon.symbol("hanger")
        XCTAssertEqual(ItemIcon(storageValue: symbol.storageValue), symbol)
        XCTAssertEqual(ItemIcon(storageValue: ""), ItemIcon.defaultIcon)
        XCTAssertEqual(ItemIcon(storageValue: "🧦"), .emoji("🧦"), "Legacy unprefixed values are treated as emoji")
        XCTAssertTrue(emoji.isEmoji)
        XCTAssertFalse(symbol.isEmoji)
    }

    func testStarterItems() {
        let starters = StarterItems.all
        XCTAssertEqual(starters.count, 12)
        XCTAssertEqual(Set(starters.map { $0.name }).count, starters.count, "Starter names are unique")
        for starter in starters {
            XCTAssertFalse(starter.name.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertGreaterThanOrEqual(starter.quantity, 1)
            XCTAssertEqual(starter.tintHex.count, 7)
            XCTAssertTrue(starter.tintHex.hasPrefix("#"))
            XCTAssertNotNil(UInt32(starter.tintHex.dropFirst(), radix: 16))
            let item = starter.makeLoadItem()
            XCTAssertEqual(item.bleedRisk, starter.bleedRisk ?? starter.colourGroup.defaultBleedRisk)
            XCTAssertEqual(item.flags, starter.flags)
        }
        XCTAssertTrue(starters.contains { $0.flags.contains(.handWashOnly) })
        XCTAssertTrue(starters.contains { $0.flags.contains(.lintShedder) })
        XCTAssertTrue(starters.contains { $0.isNew })
    }

    func testStarterLoadItemsGetDistinctIdentifiers() {
        let items = StarterItems.all.map { $0.makeLoadItem() }
        XCTAssertEqual(Set(items.map { $0.id }).count, items.count)
    }
}
