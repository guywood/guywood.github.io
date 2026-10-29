import XCTest
@testable import WashCheck

final class ConcernLevelTests: XCTestCase {

    func testThresholds() {
        XCTAssertEqual(ConcernLevel.level(for: 0), .safe)
        XCTAssertEqual(ConcernLevel.level(for: 19), .safe)
        XCTAssertEqual(ConcernLevel.level(for: 20), .mildCaution)
        XCTAssertEqual(ConcernLevel.level(for: 44), .mildCaution)
        XCTAssertEqual(ConcernLevel.level(for: 45), .caution)
        XCTAssertEqual(ConcernLevel.level(for: 69), .caution)
        XCTAssertEqual(ConcernLevel.level(for: 70), .dontWashTogether)
        XCTAssertEqual(ConcernLevel.level(for: 100), .dontWashTogether)
    }

    func testLowerBoundsMatchThresholds() {
        let weights = ScoringWeights.default
        XCTAssertEqual(ConcernLevel.safe.lowerBound(weights: weights), 0)
        XCTAssertEqual(ConcernLevel.mildCaution.lowerBound(weights: weights), weights.mildCautionThreshold)
        XCTAssertEqual(ConcernLevel.caution.lowerBound(weights: weights), weights.cautionThreshold)
        XCTAssertEqual(ConcernLevel.dontWashTogether.lowerBound(weights: weights), weights.dontWashThreshold)
    }

    func testLevelsAreOrdered() {
        XCTAssertLessThan(ConcernLevel.safe, .mildCaution)
        XCTAssertLessThan(ConcernLevel.mildCaution, .caution)
        XCTAssertLessThan(ConcernLevel.caution, .dontWashTogether)
    }

    func testCustomThresholds() {
        var weights = ScoringWeights.default
        weights.mildCautionThreshold = 10
        weights.cautionThreshold = 30
        weights.dontWashThreshold = 50
        XCTAssertEqual(ConcernLevel.level(for: 10, weights: weights), .mildCaution)
        XCTAssertEqual(ConcernLevel.level(for: 30, weights: weights), .caution)
        XCTAssertEqual(ConcernLevel.level(for: 50, weights: weights), .dontWashTogether)
    }

    func testDisplayNames() {
        XCTAssertEqual(ConcernLevel.safe.displayName, "Safe")
        XCTAssertEqual(ConcernLevel.mildCaution.displayName, "Mild caution")
        XCTAssertEqual(ConcernLevel.caution.displayName, "Caution")
        XCTAssertEqual(ConcernLevel.dontWashTogether.displayName, "Don't wash together")
    }
}
