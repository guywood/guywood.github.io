import SwiftData
import SwiftUI

/// The home screen: the washing machine, the concern gauge, the "Why?" list and the item grid.
///
/// Tapping a card flies it into the porthole (or back out). The flight overlays live in the root
/// `ZStack`, which fills the screen and declares the named coordinate space (`FrameSpace.name`)
/// that every reported frame is measured in, so `.position(x:y:)` in an overlay lands exactly
/// on the card or the glass.
@MainActor
struct LoadScreen: View {
    @Query(sort: \ClothingItem.sortOrder) private var items: [ClothingItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = LoadViewModel()
    @State private var frameStore = FrameStore()
    @State private var isAddingItem = false
    @State private var showAllConcerns = false
    @AppStorage(SettingsKeys.showNumericScores) private var showNumericScores = false

    var body: some View {
        let drumItems: [ClothingItem] = items.filter { $0.isInDrum }
        let assessment: LoadAssessment = viewModel.assessment(for: drumItems.map { $0.loadItem })
        let chips: [DrumChip] = drumItems
            .filter { !viewModel.isInFlight($0.uuid) }
            .map { item in
                DrumChip(
                    id: item.uuid,
                    name: item.name,
                    icon: item.icon,
                    tintHex: item.tintHex,
                    colourGroup: item.colourGroup,
                    quantity: item.quantity
                )
            }

        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    machineRow(chips: chips, assessment: assessment)
                    levelBlock(assessment: assessment)
                    if assessment.hasConcerns {
                        WhyListView(
                            assessment: assessment,
                            showNumericScore: showNumericScores,
                            showAll: $showAllConcerns
                        )
                    }
                    if !drumItems.isEmpty {
                        emptyDrumButton
                    }
                    ItemGridView(
                        items: items,
                        isInFlight: { itemID in viewModel.isInFlight(itemID) },
                        onTap: { item in toggle(item) },
                        onAdd: { isAddingItem = true }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .onPreferenceChange(FramePreferenceKey.self) { newFrames in
                // Newer SDKs mark this closure @Sendable; preferences are always delivered on the main actor.
                // The store is a plain class, so updating it on every scroll frame does not re-render this view.
                MainActor.assumeIsolated {
                    frameStore.update(newFrames)
                }
            }

            ForEach(viewModel.flights) { flight in
                FlightOverlayView(
                    flight: flight,
                    liveFrame: { key in frameStore.frame(for: key) },
                    onFinished: { finished in flightFinished(finished) }
                )
                .transition(.opacity.animation(.easeOut(duration: 0.15)))
            }
            .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(.named(FrameSpace.name))
        .navigationTitle("Wash Check")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingItem = true
                } label: {
                    Label("Add item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingItem) {
            ItemEditorSheet(editing: nil)
        }
    }

    // MARK: - Sections

    private func machineRow(chips: [DrumChip], assessment: LoadAssessment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            WashingMachineView(
                chips: chips,
                assessment: assessment,
                revolutionsPerSecond: viewModel.drumRevolutionsPerSecond(for: assessment),
                tintOpacity: viewModel.portholeTintOpacity(for: assessment),
                onTapChip: { chip in chipTapped(chip) }
            )
            ConcernGaugeView(assessment: assessment, showNumericScore: showNumericScores, weights: viewModel.weights)
        }
        .frame(height: 240)
        // The machine and gauge are fixed-size drawings; their captions stop scaling at the largest non-accessibility size.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func levelBlock(assessment: LoadAssessment) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(assessment.level.displayName)
                .font(.title3.bold())
                .foregroundStyle(GaugePalette.color(for: assessment.level))
            Text(assessment.headline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .animation(.easeInOut(duration: 0.25), value: assessment.level)
    }

    private var emptyDrumButton: some View {
        Button {
            emptyTheDrum()
        } label: {
            Label("Empty the drum", systemImage: "arrow.uturn.backward")
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Actions

    /// Flies the item into or out of the drum. Falls back to an instant (animated) toggle when
    /// Reduce Motion is on or the frames a flight needs have not been reported yet.
    private func toggle(_ item: ClothingItem) {
        if viewModel.isInFlight(item.uuid) {
            return
        }
        let direction: LoadViewModel.FlightDirection = item.isInDrum ? .outOfDrum : .intoDrum
        guard !reduceMotion,
              let portholeFrame = frameStore.frame(for: .porthole),
              let cardFrame = frameStore.frame(for: .card(item.uuid)) else {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.setInDrum(item, !item.isInDrum)
            }
            Haptics.impact()
            return
        }
        // Animated so the card dims and, on the way out, the chip leaves the drum as the glyph takes off.
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = viewModel.startFlight(
                for: item,
                direction: direction,
                cardFrame: cardFrame,
                portholeFrame: portholeFrame
            )
        }
    }

    /// Called by a flight overlay when its animation completes.
    private func flightFinished(_ flight: LoadViewModel.Flight) {
        // A flight cancelled by "Empty the drum" still completes its animation; it must not land or buzz.
        guard viewModel.isInFlight(flight.itemID) else { return }
        // The chip itself springs in through its own transition; the surrounding layout just eases.
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.finishFlight(flight, items: items)
        }
        switch flight.direction {
        case .intoDrum:
            Haptics.impact(.light)
        case .outOfDrum:
            Haptics.selection()
        }
    }

    /// A chip inside the porthole was tapped: fly that item back out.
    private func chipTapped(_ chip: DrumChip) {
        guard let item = items.first(where: { $0.uuid == chip.id }) else { return }
        toggle(item)
    }

    private func emptyTheDrum() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.emptyDrum(items)
        }
        Haptics.notify(.success)
    }
}
