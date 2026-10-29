import XCTest
@testable import WashCheck

final class LoadSplitterTests: XCTestCase {

    func testNoSplitWhenTheLoadIsFine() {
        let items = [TestItems.blackTees, TestItems.blackSocks]
        XCTAssertTrue(LoadSplitter().split(items).isEmpty)
        XCTAssertTrue(assessLoad(items).suggestedSplit.isEmpty)
    }

    func testNoSplitForFewerThanTwoItems() {
        XCTAssertTrue(LoadSplitter().split([]).isEmpty)
        XCTAssertTrue(LoadSplitter().split([TestItems.silkScarf]).isEmpty)
    }

    func testSplitKeepsWhitesTogetherAndAwayFromRed() {
        let items = [TestItems.whiteTees, TestItems.whiteSheets, TestItems.redHoodie, TestItems.navyJeans]
        let groups = assessLoad(items).suggestedSplit
        XCTAssertGreaterThanOrEqual(groups.count, 2)
        assertValidSplit(groups, of: items)

        let whitesGroup = groups.first { group in group.contains { $0.id == TestItems.whiteTees.id } }
        XCTAssertNotNil(whitesGroup)
        XCTAssertTrue(whitesGroup?.contains { $0.id == TestItems.whiteSheets.id } ?? false, "Whites of similar weight belong together")
        XCTAssertFalse(whitesGroup?.contains { $0.id == TestItems.redHoodie.id } ?? true, "The red hoodie must not be with the whites")
    }

    func testSplitIsolatesHandWashOnlyItem() {
        let items = [TestItems.silkScarf, TestItems.blackTees, TestItems.blackSocks, TestItems.darkLeggings]
        let groups = assessLoad(items).suggestedSplit
        assertValidSplit(groups, of: items)
        let scarfGroup = groups.first { group in group.contains { $0.id == TestItems.silkScarf.id } }
        XCTAssertNotNil(scarfGroup)
        XCTAssertLessThanOrEqual(scarfGroup?.count ?? 0, 2, "Hand-wash only tolerates at most one companion")
    }

    func testTowelsAndSilkAreSeparated() {
        let items = [TestItems.towels, TestItems.silkBlouse]
        let groups = assessLoad(items).suggestedSplit
        XCTAssertEqual(groups.count, 2)
        assertValidSplit(groups, of: items)
    }

    func testEveryGroupIsConcernFreeForTheStarterLoad() {
        let items = StarterItems.all.map { $0.makeLoadItem() }
        let result = assessLoad(items)
        XCTAssertFalse(result.concerns.isEmpty, "The full starter library is deliberately conflicting")
        XCTAssertGreaterThanOrEqual(result.suggestedSplit.count, 2)
        assertValidSplit(result.suggestedSplit, of: items)
    }

    func testGroupsPreserveOriginalOrderWithinEachGroup() {
        let items = [TestItems.whiteTees, TestItems.redHoodie, TestItems.whiteSheets, TestItems.towels]
        let groups = assessLoad(items).suggestedSplit
        let position = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($0.element.id, $0.offset) })
        for group in groups {
            let positions = group.map { position[$0.id] ?? 0 }
            XCTAssertEqual(positions, positions.sorted())
        }
    }

    func testSplitHonoursCustomWeights() {
        var weights = ScoringWeights.default
        weights.heavyWithLight = 0
        weights.highBleedWithWhitesOrLights = 0
        weights.redsExtra = 0
        let items = [TestItems.redHoodie, TestItems.whiteTees]
        XCTAssertTrue(LoadSplitter(assessor: LoadAssessor(weights: weights)).split(items).isEmpty)
        XCTAssertFalse(LoadSplitter().split(items).isEmpty)
    }

    func testSplitIsDeterministic() {
        let items = StarterItems.all.map { $0.makeLoadItem() }
        let first = LoadSplitter().split(items).map { $0.map { $0.id } }
        let second = LoadSplitter().split(items).map { $0.map { $0.id } }
        XCTAssertEqual(first, second)
    }
}
