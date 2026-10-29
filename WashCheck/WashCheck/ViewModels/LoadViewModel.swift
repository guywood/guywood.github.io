import Foundation
import Observation
import SwiftData
import SwiftUI

/// Which way a card is travelling.
enum CardFlightDirection: Hashable, Sendable {
    case intoDrum
    case outOfDrum
}

/// One card in flight between the grid and the porthole.
struct CardFlight: Identifiable, Equatable {
    let id: UUID
    /// `ClothingItem.uuid` of the item being moved.
    let itemID: UUID
    let name: String
    let icon: ItemIcon
    let tintHex: String?
    let colourGroup: ColourGroup
    let quantity: Int
    let direction: CardFlightDirection
    /// Frame of the grid card, in the Load screen's named coordinate space.
    let cardFrame: CGRect
    /// Frame of the porthole glass, in the Load screen's named coordinate space.
    let portholeFrame: CGRect

    var start: CGRect { return direction == .intoDrum ? cardFrame : portholeFrame }
    var end: CGRect { return direction == .intoDrum ? portholeFrame : cardFrame }
}

/// Drives the Load screen: memoised assessment of the drum, fly-in / fly-out bookkeeping,
/// and the presentation values derived from the assessment (drum speed, porthole tint).
///
/// The SwiftData objects stay owned by the views (`@Query`); this class only mutates the
/// `isInDrum` flag on the objects it is handed.
@MainActor
@Observable
final class LoadViewModel {

    typealias FlightDirection = CardFlightDirection
    typealias Flight = CardFlight

    /// The weights in force. Swap for a custom instance to retune the app at runtime.
    var weights: ScoringWeights = .default

    /// Cards currently animating between the grid and the drum.
    private(set) var flights: [Flight] = []

    @ObservationIgnored private var memoKey: [LoadItem] = []
    @ObservationIgnored private var memoWeights: ScoringWeights = .default
    @ObservationIgnored private var memoValue: LoadAssessment = .empty

    // MARK: - Assessment

    /// The assessment for the given drum contents. Memoised on the exact item list.
    func assessment(for drumItems: [LoadItem]) -> LoadAssessment {
        if drumItems == memoKey && weights == memoWeights {
            return memoValue
        }
        let value = assessLoad(drumItems, weights: weights)
        memoKey = drumItems
        memoWeights = weights
        memoValue = value
        return value
    }

    // MARK: - Flights

    var hasFlightsInProgress: Bool { return !flights.isEmpty }

    func isInFlight(_ itemID: UUID) -> Bool {
        return flights.contains { $0.itemID == itemID }
    }

    /// Registers a card flight. The caller animates it and calls `finishFlight` when done.
    @discardableResult
    func startFlight(for item: ClothingItem, direction: FlightDirection, cardFrame: CGRect, portholeFrame: CGRect) -> Flight {
        let flight = Flight(
            id: UUID(),
            itemID: item.uuid,
            name: item.name,
            icon: item.icon,
            tintHex: item.tintHex,
            colourGroup: item.colourGroup,
            quantity: item.quantity,
            direction: direction,
            cardFrame: cardFrame,
            portholeFrame: portholeFrame
        )
        flights.append(flight)
        return flight
    }

    /// Applies the flight's outcome to the matching item and forgets the flight.
    func finishFlight(_ flight: Flight, items: [ClothingItem]) {
        flights.removeAll { $0.id == flight.id }
        guard let item = items.first(where: { $0.uuid == flight.itemID }) else { return }
        item.isInDrum = (flight.direction == .intoDrum)
    }

    /// Drops every pending flight without applying it (used when the item set changes underneath us).
    func cancelAllFlights() {
        flights.removeAll()
    }

    /// Moves an item in or out of the drum immediately, with no flight (Reduce Motion, or a direct toggle).
    func setInDrum(_ item: ClothingItem, _ isInDrum: Bool) {
        item.isInDrum = isInDrum
    }

    /// Takes everything out of the drum.
    func emptyDrum(_ items: [ClothingItem]) {
        flights.removeAll()
        for item in items where item.isInDrum {
            item.isInDrum = false
        }
    }

    // MARK: - Presentation

    /// Drum rotation speed. Idles slowly and speeds up a little as the concern level rises.
    func drumRevolutionsPerSecond(for assessment: LoadAssessment) -> Double {
        return 0.18 + 0.32 * assessment.fraction
    }

    /// Opacity of the pink wash on the porthole glass: clear when nothing bleeds, faint pink when it does.
    func portholeTintOpacity(for assessment: LoadAssessment) -> Double {
        let bleedFraction = min(1, Double(assessment.bleedPoints) / 60)
        return bleedFraction * 0.4
    }
}
