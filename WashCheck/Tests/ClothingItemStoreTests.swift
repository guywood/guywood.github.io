import SwiftData
import XCTest
@testable import WashCheck

/// SwiftData round trips against an in-memory store.
final class ClothingItemStoreTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ClothingItem.self, configurations: configuration)
    }

    func testSeedingInsertsStartersOnceOnly() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        ClothingItem.seedIfNeeded(in: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), StarterItems.all.count)

        ClothingItem.seedIfNeeded(in: context)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ClothingItem>()), StarterItems.all.count, "Seeding again must not duplicate")
    }

    func testResetReplacesEverything() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(ClothingItem(name: "Custom", colourGroup: .darks, fabricWeight: .light, isInDrum: true))
        try context.save()

        ClothingItem.resetToStarters(in: context)
        let items = try context.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(items.count, StarterItems.all.count)
        XCTAssertFalse(items.contains { $0.name == "Custom" })
        XCTAssertTrue(items.allSatisfy { !$0.isInDrum })
    }

    func testTypedAccessorsRoundTrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let item = ClothingItem(name: "Jeans", icon: .symbol("hanger"), colourGroup: .denim, fabricWeight: .medium, flags: [.hasHardware], quantity: 2, tintHex: "#112233")
        context.insert(item)
        try context.save()

        let fetched = try XCTUnwrap(context.fetch(FetchDescriptor<ClothingItem>()).first)
        XCTAssertEqual(fetched.colourGroup, .denim)
        XCTAssertEqual(fetched.bleedRisk, .high, "Denim defaults to high")
        XCTAssertEqual(fetched.fabricWeight, .medium)
        XCTAssertEqual(fetched.flags, [.hasHardware])
        XCTAssertEqual(fetched.icon, .symbol("hanger"))
        XCTAssertEqual(fetched.quantity, 2)
        XCTAssertEqual(fetched.tintHex, "#112233")

        fetched.colourGroup = .reds
        fetched.bleedRisk = .low
        fetched.flags.insert(.lintShedder)
        XCTAssertEqual(fetched.colourGroupRaw, ColourGroup.reds.rawValue)
        XCTAssertEqual(fetched.bleedRiskRaw, BleedRisk.low.rawValue)
        XCTAssertTrue(fetched.flags.contains(.hasHardware))
        XCTAssertTrue(fetched.flags.contains(.lintShedder))

        let snapshot = fetched.loadItem
        XCTAssertEqual(snapshot.id, fetched.uuid)
        XCTAssertEqual(snapshot.name, "Jeans")
        XCTAssertEqual(snapshot.colourGroup, .reds)
        XCTAssertEqual(snapshot.bleedRisk, .low)
        XCTAssertEqual(snapshot.quantity, 2)
    }
}
