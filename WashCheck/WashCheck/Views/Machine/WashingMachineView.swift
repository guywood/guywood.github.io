import SwiftUI

/// One item shown as a chip inside the drum.
struct DrumChip: Identifiable, Hashable {
    /// `ClothingItem.uuid`.
    let id: UUID
    let name: String
    let icon: ItemIcon
    let tintHex: String?
    let colourGroup: ColourGroup
    let quantity: Int
}

/// A front-loading washing machine drawn entirely with SwiftUI shapes: a rounded body, a control
/// strip along the top (knob, indicator lights, detergent drawer) and a large round porthole whose
/// glass reports its frame under `FrameKey.porthole` so the Load screen can fly cards into it.
struct WashingMachineView: View {
    /// Items currently in the drum, in sort order.
    let chips: [DrumChip]
    let assessment: LoadAssessment
    /// From `LoadViewModel.drumRevolutionsPerSecond`.
    let revolutionsPerSecond: Double
    /// From `LoadViewModel.portholeTintOpacity` (0...0.4).
    let tintOpacity: Double
    /// Tapping a chip inside the porthole flies it back out.
    let onTapChip: (DrumChip) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let machineHeight: CGFloat = 240
    private let footHeight: CGFloat = 8
    private let bodyCornerRadius: CGFloat = 24
    private let bodyInset: CGFloat = 10
    private let controlStripHeight: CGFloat = 36

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                machineBody
                VStack(spacing: 6) {
                    controlStrip
                        .frame(height: controlStripHeight)
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 1)
                        .accessibilityHidden(true)
                    portholeArea
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(bodyInset)
            }
            feet
                .frame(height: footHeight)
        }
        .frame(height: machineHeight)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Washing machine, \(chips.count) items in the drum")
    }

    // MARK: - Body and feet

    private var machineBody: some View {
        RoundedRectangle(cornerRadius: bodyCornerRadius, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: bodyCornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .accessibilityHidden(true)
    }

    private var feet: some View {
        HStack {
            foot
            Spacer(minLength: 0)
            foot
        }
        .padding(.horizontal, 22)
        .accessibilityHidden(true)
    }

    private var foot: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color(.systemGray3))
            .frame(width: 18, height: 6)
    }

    // MARK: - Control strip

    private var controlStrip: some View {
        HStack(spacing: 12) {
            knob
            indicatorLights
            Spacer(minLength: 0)
            detergentDrawer
        }
        .accessibilityHidden(true)
    }

    private var knob: some View {
        ZStack(alignment: .top) {
            Circle()
                .fill(Color(.tertiarySystemBackground))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.18), lineWidth: 1.5))
            Capsule()
                .fill(Color.primary.opacity(0.5))
                .frame(width: 3, height: 8)
                .padding(.top, 4)
        }
        .frame(width: 28, height: 28)
    }

    /// Three lights. More of them light up as the level rises, in the level's colour.
    private var indicatorLights: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < litLightCount ? litColor : Color(.systemGray4))
                    .frame(width: 8, height: 8)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: index < litLightCount ? litColor.opacity(0.7) : Color.clear, radius: 3, x: 0, y: 0)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: assessment.level)
    }

    private var litColor: Color {
        return GaugePalette.color(for: assessment.level)
    }

    private var litLightCount: Int {
        return min(3, assessment.level.rawValue + 1)
    }

    private var detergentDrawer: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1.5)
            .frame(width: 40, height: 16)
            .overlay(
                Capsule()
                    .fill(Color.primary.opacity(0.25))
                    .frame(width: 14, height: 2)
            )
    }

    // MARK: - Porthole

    private var portholeArea: some View {
        GeometryReader { proxy in
            let ringDiameter: CGFloat = max(40, min(proxy.size.width, proxy.size.height) - 4)
            let glassDiameter: CGFloat = ringDiameter * 0.84

            ZStack {
                // Door ring.
                Circle()
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                    .frame(width: ringDiameter, height: ringDiameter)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .accessibilityHidden(true)

                // Door latch on the right of the ring.
                Capsule()
                    .fill(Color.primary.opacity(0.25))
                    .frame(width: 6, height: 22)
                    .offset(x: ringDiameter / 2 - 7)
                    .accessibilityHidden(true)

                // Bevel between the ring and the glass.
                Circle()
                    .strokeBorder(Color.primary.opacity(0.14), lineWidth: 4)
                    .frame(width: glassDiameter + 8, height: glassDiameter + 8)
                    .accessibilityHidden(true)

                portholeGlass(diameter: glassDiameter)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// The circular glass: the drum behind it, the chips, the tint and the reflection.
    /// This is the view that reports `FrameKey.porthole`.
    private func portholeGlass(diameter: CGFloat) -> some View {
        ZStack {
            // Drum back.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(.systemGray5), Color(.systemGray3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter / 2
                    )
                )
                .accessibilityHidden(true)

            DrumView(
                chips: chips,
                glassDiameter: diameter,
                revolutionsPerSecond: revolutionsPerSecond,
                reduceMotion: reduceMotion,
                onTapChip: onTapChip
            )

            if chips.isEmpty {
                Text("Tap items below")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            // Pink wash when something in the load may bleed.
            Circle()
                .fill(Color.pink)
                .opacity(tintOpacity)
                .animation(.easeInOut(duration: 0.4), value: tintOpacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // Glass reflection.
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.04), Color.white.opacity(0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            // Glass rim.
            Circle()
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .reportFrame(.porthole)
    }
}

#Preview {
    WashingMachineView(
        chips: [
            DrumChip(id: UUID(), name: "Red hoodie", icon: .emoji("🧥"), tintHex: "#F8C4C4", colourGroup: .reds, quantity: 1),
            DrumChip(id: UUID(), name: "White t-shirts", icon: .emoji("👕"), tintHex: "#F4F4F0", colourGroup: .whites, quantity: 3),
            DrumChip(id: UUID(), name: "Denim jacket", icon: .symbol("hanger"), tintHex: nil, colourGroup: .denim, quantity: 1),
        ],
        assessment: .empty,
        revolutionsPerSecond: 0.3,
        tintOpacity: 0.2,
        onTapChip: { _ in }
    )
    .padding()
}
