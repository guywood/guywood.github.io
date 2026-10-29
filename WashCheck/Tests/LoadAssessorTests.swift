import XCTest
@testable import WashCheck

final class LoadAssessorTests: XCTestCase {

    // MARK: - Required cases

    func testEmptyLoadIsSafeAndEmpty() {
        let result = assessLoad([])
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.uncappedScore, 0)
        XCTAssertEqual(result.level, .safe)
        XCTAssertTrue(result.concerns.isEmpty)
        XCTAssertTrue(result.suggestedSplit.isEmpty)
        XCTAssertTrue(result.isEmptyLoad)
        XCTAssertEqual(result.headline, LoadAssessment.empty.headline)
        XCTAssertEqual(result, LoadAssessment.empty)
    }

    func testSingleItemIsSafe() {
        let result = assessLoad([TestItems.redHoodie])
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.level, .safe)
        XCTAssertTrue(result.concerns.isEmpty)
        XCTAssertTrue(result.suggestedSplit.isEmpty)
        XCTAssertFalse(result.isEmptyLoad)
        XCTAssertEqual(result.itemCount, 1)
        XCTAssertEqual(result.headline, "One item, nothing to clash with.")
    }

    func testRedHoodieWithWhitesIsFlaggedForBleedingAndWeight() {
        let hoodie = TestItems.redHoodie
        let tees = TestItems.whiteTees
        let result = assessLoad([hoodie, tees])

        let bleed = result.concerns(withPrefix: "bleed")
        XCTAssertEqual(bleed.count, 1)
        XCTAssertEqual(bleed.first?.severity, .high)
        XCTAssertEqual(bleed.first?.points, 40 + 15, "High bleed onto whites plus the reds extra")
        XCTAssertEqual(bleed.first?.itemIDs, [hoodie.id, tees.id])
        XCTAssertEqual(bleed.first?.message, "Red hoodie may bleed onto White t-shirts.")

        let weight = result.concerns(withPrefix: "weight")
        XCTAssertEqual(weight.count, 1, "A heavy hoodie with a light t-shirt is a thickness mismatch too")
        XCTAssertEqual(weight.first?.points, 15)
        XCTAssertEqual(weight.first?.severity, .medium)

        XCTAssertEqual(result.bleedPoints, 55)
        XCTAssertEqual(result.fabricPoints, 15)
        XCTAssertEqual(result.score, 70)
        XCTAssertEqual(result.level, .dontWashTogether)
        XCTAssertEqual(result.headline, "Red hoodie may bleed onto White t-shirts.")
        XCTAssertEqual(result.concerns.first?.id, bleed.first?.id, "The worst concern comes first")
        XCTAssertEqual(result.suggestedSplit.count, 2)
    }

    func testTowelsWithSilkAreFlaggedForAbrasionLintAndSpan() {
        let towels = TestItems.towels
        let silk = TestItems.silkBlouse
        let result = assessLoad([towels, silk])

        let weight = result.concerns(withPrefix: "weight")
        XCTAssertEqual(weight.count, 1)
        XCTAssertEqual(weight.first?.points, 35)
        XCTAssertEqual(weight.first?.severity, .high)
        XCTAssertEqual(weight.first?.message, "Bath towels will abrade and snag Silk blouse.")

        let lint = result.concerns(withPrefix: "lint")
        XCTAssertEqual(lint.count, 1)
        XCTAssertEqual(lint.first?.points, 15)
        XCTAssertEqual(lint.first?.severity, .medium)
        XCTAssertEqual(lint.first?.itemIDs, [towels.id, silk.id])

        let span = result.concerns(withPrefix: "span")
        XCTAssertEqual(span.count, 1)
        XCTAssertEqual(span.first?.points, 10)
        XCTAssertEqual(span.first?.severity, .low)
        XCTAssertEqual(span.first?.kind, .wholeLoad)

        XCTAssertTrue(result.concerns(withPrefix: "bleed").isEmpty, "Whites and lights do not bleed")
        XCTAssertEqual(result.bleedPoints, 0)
        XCTAssertEqual(result.fabricPoints, 60)
        XCTAssertEqual(result.score, 60)
        XCTAssertEqual(result.level, .caution)
        XCTAssertEqual(result.concerns.first?.id, weight.first?.id)
        XCTAssertEqual(result.suggestedSplit.count, 2)
    }

    func testAllDarksOfTheSameWeightAreSafe() {
        let items = [TestItems.blackTees, TestItems.blackSocks, TestItems.darkLeggings]
        let result = assessLoad(items)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.level, .safe)
        XCTAssertTrue(result.concerns.isEmpty)
        XCTAssertTrue(result.suggestedSplit.isEmpty)
        XCTAssertEqual(result.headline, ConcernLevel.safe.advice)
    }

    func testHandWashOnlyItemIsFlaggedWithTwoOrMoreOthers() {
        let scarf = TestItems.silkScarf
        let withOne = assessLoad([scarf, TestItems.blackSocks])
        XCTAssertTrue(withOne.concerns(withPrefix: "handwash").isEmpty, "One other item is allowed")

        let withTwo = assessLoad([scarf, TestItems.blackSocks, TestItems.blackTees])
        let handwash = withTwo.concerns(withPrefix: "handwash")
        XCTAssertEqual(handwash.count, 1)
        XCTAssertEqual(handwash.first?.points, 25)
        XCTAssertEqual(handwash.first?.severity, .high)
        XCTAssertEqual(handwash.first?.itemIDs, [scarf.id])
        XCTAssertEqual(withTwo.concerns.count, 1, "Darks with a bright delicate raise no other concern")
        XCTAssertEqual(withTwo.score, 25)
        XCTAssertEqual(withTwo.level, .mildCaution)
        XCTAssertEqual(withTwo.suggestedSplit.count, 2)
    }

    // MARK: - Colour bleeding rules

    func testSameColourGroupNeverBleeds() {
        let a = TestItems.item("Red socks", .reds, .light)
        let b = TestItems.item("Pink top", .reds, .light)
        let result = assessLoad([a, b])
        XCTAssertTrue(result.concerns.isEmpty)
        XCTAssertEqual(result.score, 0)
    }

    func testMediumBleedWithWhitesAndLights() {
        let darks = TestItems.blackTees
        let withWhites = assessLoad([darks, TestItems.whiteTees])
        XCTAssertEqual(withWhites.concerns.count, 1)
        XCTAssertEqual(withWhites.concerns.first?.points, 20)
        XCTAssertEqual(withWhites.concerns.first?.severity, .medium)

        let withLights = assessLoad([darks, TestItems.pastelBlouse])
        XCTAssertEqual(withLights.concerns.count, 1)
        XCTAssertEqual(withLights.concerns.first?.points, 10)
        XCTAssertEqual(withLights.concerns.first?.severity, .low)
        XCTAssertEqual(withLights.level, .safe, "10 points is still below the mild-caution threshold")
    }

    func testHighBleedWithBrightsOfAnotherGroup() {
        let jeans = TestItems.item("Blue jeans", .denim, .light)
        let withBrights = assessLoad([jeans, TestItems.yellowTee])
        XCTAssertEqual(withBrights.concerns.count, 1)
        XCTAssertEqual(withBrights.concerns.first?.points, 20)
        XCTAssertEqual(withBrights.concerns.first?.severity, .medium)

        let withDarks = assessLoad([jeans, TestItems.blackTees])
        XCTAssertTrue(withDarks.concerns.isEmpty, "High bleed next to darks is fine")
    }

    func testNewItemIsBumpedOneLevelAndAddsExtra() {
        let newDark = TestItems.item("New black jeans", .darks, .light, isNew: true)
        XCTAssertEqual(newDark.bleedRisk, .medium)
        XCTAssertEqual(newDark.effectiveBleedRisk, .high)

        let result = assessLoad([newDark, TestItems.pastelBlouse])
        XCTAssertEqual(result.concerns.count, 1)
        XCTAssertEqual(result.concerns.first?.severity, .high, "Bumped to high, so lights are a high-severity target")
        XCTAssertEqual(result.concerns.first?.points, 40 + 10)
    }

    func testNewReceivingItemAlsoAddsExtra() {
        let newTees = TestItems.item("New white t-shirts", .whites, .heavy, isNew: true)
        let result = assessLoad([TestItems.redHoodie, newTees])
        let bleed = result.concerns(withPrefix: "bleed")
        XCTAssertEqual(bleed.count, 1)
        XCTAssertEqual(bleed.first?.points, 40 + 15 + 10)
    }

    func testBothItemsNewAddsExtraTwice() {
        let hoodie = TestItems.item("New red hoodie", .reds, .light, isNew: true)
        let tees = TestItems.item("New white t-shirts", .whites, .light, isNew: true)
        let bleed = assessLoad([hoodie, tees]).concerns(withPrefix: "bleed")
        XCTAssertEqual(bleed.first?.points, 40 + 15 + 10 + 10)
    }

    func testHighBleedNeverExceedsHigh() {
        let item = TestItems.item("Brand new red", .reds, .light, isNew: true)
        XCTAssertEqual(item.effectiveBleedRisk, .high)
        XCTAssertEqual(BleedRisk.high.bumpedUp, .high)
    }

    func testRedsExtraStandsAloneWhenRiskIsLow() {
        let fadedRed = TestItems.item("Faded red tee", .reds, .light, bleed: .low)
        let withWhites = assessLoad([fadedRed, TestItems.whiteTees])
        XCTAssertEqual(withWhites.concerns.count, 1)
        XCTAssertEqual(withWhites.concerns.first?.points, 15)
        XCTAssertEqual(withWhites.concerns.first?.severity, .low)
        XCTAssertEqual(withWhites.concerns.first?.kind, .colourBleeding)
        XCTAssertTrue(withWhites.concerns.first?.message.contains("classic dye culprit") ?? false)

        let withDarks = assessLoad([fadedRed, TestItems.blackTees])
        XCTAssertTrue(withDarks.concerns(withPrefix: "bleed").isEmpty, "Reds with darks is exempt from the extra")

        let withDenim = assessLoad([fadedRed, TestItems.item("Jeans", .denim, .light, bleed: .low)])
        XCTAssertEqual(withDenim.concerns(withPrefix: "bleed").first?.points, 15, "Denim is not darks, so the extra applies")
    }

    func testRedsExtraIsCountedOncePerPair() {
        let result = assessLoad([TestItems.whiteTees, TestItems.item("Red tee", .reds, .light)])
        XCTAssertEqual(result.concerns.count, 1)
        XCTAssertEqual(result.score, 55)
    }

    func testLowBleedItemsRaiseNoBleedConcern() {
        let faded = TestItems.item("Faded black tee", .darks, .light, bleed: .low)
        let result = assessLoad([faded, TestItems.whiteTees])
        XCTAssertTrue(result.concerns.isEmpty)
    }

    // MARK: - Fabric rules

    func testWeightPairRules() {
        func points(_ a: FabricWeight, _ b: FabricWeight) -> Int {
            let x = TestItems.item("A", .darks, a)
            let y = TestItems.item("B", .darks, b)
            return assessLoad([x, y]).concerns(withPrefix: "weight").first?.points ?? 0
        }
        XCTAssertEqual(points(.heavy, .delicate), 35)
        XCTAssertEqual(points(.delicate, .heavy), 35, "Order does not matter")
        XCTAssertEqual(points(.heavy, .light), 15)
        XCTAssertEqual(points(.medium, .delicate), 15)
        XCTAssertEqual(points(.heavy, .medium), 0)
        XCTAssertEqual(points(.medium, .light), 0)
        XCTAssertEqual(points(.light, .delicate), 0)
        XCTAssertEqual(points(.heavy, .heavy), 0)
    }

    func testLintShedderWithDarks() {
        let result = assessLoad([TestItems.towels, TestItems.blackSocks])
        let lint = result.concerns(withPrefix: "lint")
        XCTAssertEqual(lint.count, 1)
        XCTAssertEqual(lint.first?.points, 15)
        XCTAssertTrue(lint.first?.message.contains("shows on") ?? false)
    }

    func testTwoLintSheddersTogetherAreFine() {
        let darkTowel = TestItems.item("Dark towel", .darks, .heavy, flags: [.lintShedder])
        let result = assessLoad([TestItems.fleeceThrow, darkTowel])
        XCTAssertTrue(result.concerns(withPrefix: "lint").isEmpty)
        XCTAssertTrue(result.concerns.isEmpty)
    }

    func testLintShedderWithDelicateNonDarkItem() {
        let result = assessLoad([TestItems.fleeceThrow, TestItems.laceUnderwear])
        let lint = result.concerns(withPrefix: "lint")
        XCTAssertEqual(lint.count, 1)
        XCTAssertTrue(lint.first?.message.contains("clings to") ?? false)
    }

    func testHardwareWithDelicate() {
        let result = assessLoad([TestItems.navyJeans, TestItems.laceUnderwear])
        let hardware = result.concerns(withPrefix: "hardware")
        XCTAssertEqual(hardware.count, 1)
        XCTAssertEqual(hardware.first?.points, 20)
        XCTAssertEqual(hardware.first?.severity, .high)
        XCTAssertEqual(result.concerns(withPrefix: "weight").first?.points, 15, "Medium with delicate")
        XCTAssertEqual(result.concerns(withPrefix: "bleed").first?.points, 40, "Denim is high bleed next to lights")
        XCTAssertEqual(result.score, 75)
        XCTAssertEqual(result.level, .dontWashTogether)
    }

    func testHardwareWithoutDelicateIsFine() {
        let result = assessLoad([TestItems.navyJeans, TestItems.blackTees])
        XCTAssertTrue(result.concerns(withPrefix: "hardware").isEmpty)
    }

    func testWoolWithHeavy() {
        let result = assessLoad([TestItems.woolJumper, TestItems.greyHoodie])
        let wool = result.concerns(withPrefix: "wool")
        XCTAssertEqual(wool.count, 1)
        XCTAssertEqual(wool.first?.points, 15)
        XCTAssertEqual(wool.first?.itemIDs, [TestItems.woolJumper.id, TestItems.greyHoodie.id], "The wool item is named first")
        XCTAssertEqual(result.concerns.count, 1)

        let withMedium = assessLoad([TestItems.woolJumper, TestItems.item("Sweatshirt", .darks, .medium)])
        XCTAssertTrue(withMedium.concerns.isEmpty, "Wool with medium weight is fine")
    }

    func testWoolConcernIsCountedOncePerPair() {
        let a = TestItems.item("Wool blanket", .darks, .heavy, flags: [.woolOrCashmere])
        let b = TestItems.item("Wool coat", .darks, .heavy, flags: [.woolOrCashmere])
        XCTAssertEqual(assessLoad([a, b]).concerns(withPrefix: "wool").count, 1)
    }

    func testAthleticWithHeavyLintShedder() {
        let result = assessLoad([TestItems.gymKit, TestItems.fleeceThrow])
        let athletic = result.concerns(withPrefix: "athletic")
        XCTAssertEqual(athletic.count, 1)
        XCTAssertEqual(athletic.first?.points, 10)
        XCTAssertEqual(athletic.first?.severity, .low)

        let lightShedder = TestItems.item("Flannel shirt", .darks, .light, flags: [.lintShedder])
        XCTAssertTrue(assessLoad([TestItems.gymKit, lightShedder]).concerns(withPrefix: "athletic").isEmpty, "Only heavy shedders count")
    }

    func testMixedWeightSpanIsAddedOnce() {
        let items = [TestItems.greyHoodie, TestItems.fleeceThrow, TestItems.item("Silk cami", .darks, .delicate), TestItems.item("Lace top", .darks, .delicate)]
        let result = assessLoad(items)
        XCTAssertEqual(result.concerns(withPrefix: "span").count, 1)
        XCTAssertTrue(result.concerns(withPrefix: "span").first?.itemIDs.isEmpty ?? false)
    }

    func testNoSpanWithoutBothExtremes() {
        let result = assessLoad([TestItems.greyHoodie, TestItems.blackTees])
        XCTAssertTrue(result.concerns(withPrefix: "span").isEmpty)
    }

    // MARK: - Scoring mechanics

    func testScoreIsCappedAtMaximum() {
        let items = [TestItems.redHoodie, TestItems.whiteTees, TestItems.whiteSheets, TestItems.towels, TestItems.silkBlouse, TestItems.navyJeans, TestItems.denimJacket]
        let result = assessLoad(items)
        XCTAssertGreaterThan(result.uncappedScore, 100)
        XCTAssertEqual(result.score, 100)
        XCTAssertEqual(result.level, .dontWashTogether)
        XCTAssertEqual(result.fraction, 1, accuracy: 0.0001)
    }

    func testPairOrderDoesNotChangeTheResult() {
        let forward = assessLoad([TestItems.redHoodie, TestItems.whiteTees, TestItems.towels])
        let backward = assessLoad([TestItems.towels, TestItems.whiteTees, TestItems.redHoodie])
        XCTAssertEqual(forward.score, backward.score)
        XCTAssertEqual(Set(forward.concerns.map { $0.id }), Set(backward.concerns.map { $0.id }))
    }

    func testConcernsAreSortedWorstFirst() {
        let result = assessLoad([TestItems.towels, TestItems.silkBlouse, TestItems.blackSocks])
        let severities = result.concerns.map { $0.severity.rawValue }
        XCTAssertEqual(severities, severities.sorted(by: >))
        for (lhs, rhs) in zip(result.concerns, result.concerns.dropFirst()) where lhs.severity == rhs.severity {
            XCTAssertGreaterThanOrEqual(lhs.points, rhs.points)
        }
    }

    func testBleedAndFabricPointsAddUpToTheUncappedScore() {
        let result = assessLoad([TestItems.redHoodie, TestItems.whiteTees, TestItems.towels, TestItems.silkBlouse])
        XCTAssertEqual(result.bleedPoints + result.fabricPoints, result.uncappedScore)
        XCTAssertEqual(result.concerns.reduce(0) { $0 + $1.points }, result.uncappedScore)
    }

    func testCustomWeightsAreHonoured() {
        var weights = ScoringWeights.default
        weights.highBleedWithWhitesOrLights = 60
        weights.redsExtra = 0
        weights.heavyWithLight = 0
        let result = assessLoad([TestItems.redHoodie, TestItems.whiteTees], weights: weights)
        XCTAssertEqual(result.score, 60)

        weights.maximumScore = 50
        let capped = assessLoad([TestItems.redHoodie, TestItems.whiteTees], weights: weights)
        XCTAssertEqual(capped.score, 50)
        XCTAssertEqual(capped.maximumScore, 50)
        XCTAssertEqual(capped.fraction, 1, accuracy: 0.0001)
    }

    func testConcernIDsAreStableAcrossRuns() {
        let a = TestItems.redHoodie
        let b = TestItems.whiteTees
        let first = assessLoad([a, b]).concerns.map { $0.id }
        let second = assessLoad([a, b]).concerns.map { $0.id }
        XCTAssertEqual(first, second)
    }

    func testConcernsInvolvingAnItem() {
        let hoodie = TestItems.redHoodie
        let result = assessLoad([hoodie, TestItems.whiteTees, TestItems.blackSocks])
        let involving = result.concerns(involving: hoodie.id)
        XCTAssertFalse(involving.isEmpty)
        XCTAssertTrue(involving.allSatisfy { $0.itemIDs.contains(hoodie.id) })
    }

    func testQuantityDoesNotChangeTheScore() {
        var tees = TestItems.whiteTees
        tees.quantity = 6
        let single = assessLoad([TestItems.redHoodie, TestItems.whiteTees]).score
        let many = assessLoad([TestItems.redHoodie, tees]).score
        XCTAssertEqual(single, many)
    }
}
