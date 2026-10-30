import SwiftUI

/// The rotating contents of the porthole: three drum fins and the item chips tumbling around a ring.
///
/// Rotation is driven by a `TimelineView` that pauses while the drum is empty (or Reduce Motion
/// is on). The angle is anchored to a date so that a change of speed never makes it jump:
/// `angle(now) = anchorAngle + 360 * revolutionsPerSecond * (now - anchorDate)`.
struct DrumView: View {
    let chips: [DrumChip]
    let glassDiameter: CGFloat
    let revolutionsPerSecond: Double
    let reduceMotion: Bool
    let onTapChip: (DrumChip) -> Void

    @State private var anchorDate: Date = Date()
    @State private var anchorAngle: Double = 0

    /// At most this many chips are drawn; beyond it the last slot becomes a "+N" chip.
    private static let maximumVisibleChips: Int = 8

    /// One drawn position in the drum: a real item chip or the overflow counter.
    private enum Slot: Identifiable {
        case chip(DrumChip)
        case overflow(Int)

        var id: String {
            switch self {
            case .chip(let chip):
                return chip.id.uuidString
            case .overflow:
                return "overflow"
            }
        }
    }

    /// A slot together with its index around the ring.
    private struct PlacedSlot: Identifiable {
        let slot: Slot
        let index: Int

        var id: String { return slot.id }
    }

    private var slots: [Slot] {
        if chips.count <= DrumView.maximumVisibleChips {
            return chips.map { Slot.chip($0) }
        }
        let shown: [Slot] = chips.prefix(DrumView.maximumVisibleChips - 1).map { Slot.chip($0) }
        return shown + [Slot.overflow(chips.count - shown.count)]
    }

    var body: some View {
        TimelineView(.animation(paused: chips.isEmpty || reduceMotion)) { context in
            drum(angle: angle(at: context.date))
        }
        .frame(width: glassDiameter, height: glassDiameter)
        .onChange(of: revolutionsPerSecond) { oldValue, _ in
            reanchor(previousRevolutionsPerSecond: oldValue)
        }
        .onChange(of: chips.isEmpty) { _, isEmpty in
            if isEmpty {
                // Freeze at the current angle while the drum is empty.
                reanchor(previousRevolutionsPerSecond: revolutionsPerSecond)
            } else {
                // Resume from the frozen angle.
                anchorDate = Date()
            }
        }
    }

    // MARK: - Angle

    private func angle(at date: Date) -> Double {
        if reduceMotion {
            return 0
        }
        return anchorAngle + 360 * revolutionsPerSecond * date.timeIntervalSince(anchorDate)
    }

    /// Moves the anchor to "now" so the angle stays continuous when the speed changes.
    private func reanchor(previousRevolutionsPerSecond: Double) {
        let now = Date()
        let elapsed: Double = now.timeIntervalSince(anchorDate)
        let current: Double = anchorAngle + 360 * previousRevolutionsPerSecond * elapsed
        anchorAngle = current.truncatingRemainder(dividingBy: 360)
        anchorDate = now
    }

    // MARK: - Drawing

    private func drum(angle: Double) -> some View {
        let radius: CGFloat = glassDiameter / 2
        let center = CGPoint(x: radius, y: radius)
        let placed: [PlacedSlot] = slots.enumerated().map { PlacedSlot(slot: $0.element, index: $0.offset) }
        let chipDiameter: CGFloat = placed.count > 6 ? 30 : 34

        return ZStack {
            // Hub in the middle of the drum.
            Circle()
                .fill(Color(.systemGray4))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
                .frame(width: radius * 0.34, height: radius * 0.34)
                .accessibilityHidden(true)

            // Three fins, spaced 120° apart, orbiting the centre.
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(.systemGray2).opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .frame(width: 9, height: radius * 0.38)
                    .offset(y: -radius * 0.74)
                    .rotationEffect(.degrees(angle + Double(index) * 120))
                    .accessibilityHidden(true)
            }

            // Chips around the ring. The whole ring turns with the drum; each glyph counter-rotates
            // so it stays upright. Slot positions depend only on the chip count, so when a chip lands
            // or leaves, the others glide to their new slots instead of snapping.
            ZStack {
                ForEach(placed) { item in
                    slotView(item.slot, diameter: chipDiameter)
                        .rotationEffect(.degrees(-angle))
                        .transition(chipTransition)
                        .position(chipPosition(index: item.index, count: placed.count, center: center, radius: radius))
                }
            }
            .frame(width: glassDiameter, height: glassDiameter)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: placed.count)
            .rotationEffect(.degrees(angle))
        }
        .frame(width: glassDiameter, height: glassDiameter)
    }

    private var chipTransition: AnyTransition {
        if reduceMotion {
            return AnyTransition.opacity
        }
        return AnyTransition.scale
            .combined(with: .opacity)
            .animation(.spring(response: 0.35, dampingFraction: 0.5))
    }

    private func slotView(_ slot: Slot, diameter: CGFloat) -> some View {
        Group {
            switch slot {
            case .chip(let chip):
                DrumItemChip(chip: chip, diameter: diameter, action: { onTapChip(chip) })
            case .overflow(let count):
                DrumOverflowChip(count: count, diameter: diameter)
            }
        }
    }

    /// Where chip `index` of `count` sits before the drum's rotation is applied: evenly spaced
    /// around a ring (about 55 % of the glass radius, alternating slightly in and out so neighbours
    /// overlap less).
    private func chipPosition(index: Int, count: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let safeCount: Int = max(1, count)
        let baseAngle: Double = 360.0 * Double(index) / Double(safeCount)
        let ringFraction: Double = (index % 2 == 0) ? 0.49 : 0.61
        let ringRadius: CGFloat = radius * CGFloat(ringFraction)
        let radians: Double = (baseAngle - 90) * Double.pi / 180
        let x: CGFloat = center.x + ringRadius * CGFloat(cos(radians))
        let y: CGFloat = center.y + ringRadius * CGFloat(sin(radians))
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Chips

/// One item inside the drum. Tapping it flies the item back out.
private struct DrumItemChip: View {
    let chip: DrumChip
    let diameter: CGFloat
    let action: () -> Void

    private var tint: Color {
        return itemTint(hex: chip.tintHex, colourGroup: chip.colourGroup)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(tint)
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                ItemIconView(icon: chip.icon, size: 18)
                    .environment(\.colorScheme, tint.contrastingScheme)
            }
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .topTrailing) {
                if chip.quantity > 1 {
                    Text("×\(chip.quantity)")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color(.systemBackground)))
                        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5))
                        .offset(x: 6, y: -4)
                }
            }
            .shadow(color: Color.black.opacity(0.18), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(chip.name), in drum")
        .accessibilityHint("Double tap to take it out")
    }
}

/// The "+N" chip shown when more items are in the drum than fit around the ring.
private struct DrumOverflowChip: View {
    let count: Int
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground).opacity(0.85))
            Circle()
                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
            Text("+\(count)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel("\(count) more items in the drum")
    }
}
