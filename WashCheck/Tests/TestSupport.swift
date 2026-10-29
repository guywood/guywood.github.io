import Foundation
import XCTest
@testable import WashCheck

/// Builders for the items the tests share.
enum TestItems {
    static func item(
        _ name: String,
        _ group: ColourGroup,
        _ weight: FabricWeight,
        bleed: BleedRisk? = nil,
        isNew: Bool = false,
        flags: ItemFlags = []
    ) -> LoadItem {
        return LoadItem(name: name, colourGroup: group, bleedRisk: bleed, isNew: isNew, fabricWeight: weight, flags: flags)
    }

    static let whiteTees: LoadItem = item("White t-shirts", .whites, .light)
    static let whiteSheets: LoadItem = item("White sheets", .whites, .medium)
    static let towels: LoadItem = item("Bath towels", .whites, .heavy, flags: [.lintShedder])
    static let pastelBlouse: LoadItem = item("Pastel blouse", .lights, .light)
    static let silkBlouse: LoadItem = item("Silk blouse", .lights, .delicate)
    static let laceUnderwear: LoadItem = item("Lace underwear", .lights, .delicate)
    static let silkScarf: LoadItem = item("Silk scarf", .brights, .delicate, flags: [.handWashOnly])
    static let gymKit: LoadItem = item("Gym kit", .brights, .light, flags: [.athletic])
    static let yellowTee: LoadItem = item("Yellow t-shirt", .brights, .light)
    static let navyJeans: LoadItem = item("Navy jeans", .denim, .medium, flags: [.hasHardware])
    static let denimJacket: LoadItem = item("Denim jacket", .denim, .heavy, isNew: true, flags: [.hasHardware])
    static let redHoodie: LoadItem = item("Red hoodie", .reds, .heavy)
    static let blackTees: LoadItem = item("Black t-shirts", .darks, .light)
    static let blackSocks: LoadItem = item("Black socks", .darks, .light)
    static let darkLeggings: LoadItem = item("Dark leggings", .darks, .light)
    static let greyHoodie: LoadItem = item("Grey hoodie", .darks, .heavy)
    static let woolJumper: LoadItem = item("Wool jumper", .darks, .medium, flags: [.woolOrCashmere])
    static let fleeceThrow: LoadItem = item("Fleece throw", .darks, .heavy, flags: [.lintShedder])
}

extension LoadAssessment {
    /// Concern identifiers whose prefix matches, e.g. `"bleed"`.
    func concerns(withPrefix prefix: String) -> [Concern] {
        return concerns.filter { $0.id.hasPrefix(prefix + ":") || $0.id == prefix }
    }
}

extension XCTestCase {
    /// Asserts that every group is concern-free and that the groups partition the input exactly.
    func assertValidSplit(_ groups: [[LoadItem]], of items: [LoadItem], weights: ScoringWeights = .default, file: StaticString = #filePath, line: UInt = #line) {
        let assessor = LoadAssessor(weights: weights)
        for group in groups {
            let result = assessor.assess(group, includeSplit: false)
            XCTAssertTrue(result.concerns.isEmpty, "Group \(group.map { $0.name }) still has concerns: \(result.concerns.map { $0.message })", file: file, line: line)
        }
        let flattened = groups.flatMap { $0 }.map { $0.id }
        XCTAssertEqual(flattened.count, items.count, "Split should contain every item exactly once", file: file, line: line)
        XCTAssertEqual(Set(flattened), Set(items.map { $0.id }), "Split should contain exactly the input items", file: file, line: line)
    }
}
