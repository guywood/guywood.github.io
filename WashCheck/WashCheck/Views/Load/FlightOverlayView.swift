import SwiftUI

/// A card-like glyph that flies along an arc between a grid card and the porthole glass.
///
/// The Load screen places one of these in its root `ZStack` for every `LoadViewModel.Flight`.
/// Both endpoints are expressed in the Load screen's named coordinate space (`FrameSpace.name`),
/// which that `ZStack` declares, so the frames collected by `reportFrame(_:)` are used directly.
///
/// Main-actor isolated because it reads `LoadViewModel.Flight`, a nested type of a `@MainActor` class,
/// outside `body`; it is only ever created from the Load screen's `body`.
@MainActor
struct FlightOverlayView: View {
    let flight: LoadViewModel.Flight
    let onFinished: (LoadViewModel.Flight) -> Void

    @State private var progress: CGFloat = 0

    init(flight: LoadViewModel.Flight, onFinished: @escaping (LoadViewModel.Flight) -> Void) {
        self.flight = flight
        self.onFinished = onFinished
    }

    /// Cards shrink as they drop into the drum and grow back as they come out.
    private var startScale: CGFloat {
        return flight.direction == .intoDrum ? 1.0 : 0.5
    }

    private var endScale: CGFloat {
        return flight.direction == .intoDrum ? 0.5 : 1.0
    }

    var body: some View {
        glyph
            .modifier(
                FlightPathModifier(
                    progress: progress,
                    start: flight.start,
                    end: flight.end,
                    startScale: startScale,
                    endScale: endScale
                )
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55)) {
                    progress = 1
                } completion: {
                    onFinished(flight)
                }
            }
    }

    /// The flying card: tinted rounded square with the item's icon and a quantity badge.
    private var glyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(itemTint(hex: flight.tintHex, colourGroup: flight.colourGroup))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            ItemIconView(icon: flight.icon, size: 30)
        }
        .frame(width: 64, height: 64)
        .overlay(alignment: .topTrailing) {
            if flight.quantity > 1 {
                Text("×\(flight.quantity)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(.systemBackground)))
                    .offset(x: 6, y: -6)
            }
        }
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

/// Moves its content along a quadratic Bézier arc from the centre of `start` to the centre of `end`
/// as `progress` goes from 0 to 1, scaling it from `startScale` to `endScale` on the way.
///
/// `progress` is the animatable data, so `withAnimation { progress = 1 }` sweeps the whole path.
/// Placement uses `.position(x:y:)`, i.e. the parent's coordinate space: the parent must be the
/// Load screen's root `ZStack`, which fills the screen and declares `FrameSpace.name`.
struct FlightPathModifier: ViewModifier, Animatable {
    var progress: CGFloat
    let start: CGRect
    let end: CGRect
    let startScale: CGFloat
    let endScale: CGFloat

    /// How far above the higher of the two endpoints the control point sits, in points.
    static let lift: CGFloat = 120

    var animatableData: CGFloat {
        get { return progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(currentScale)
            .position(x: currentPoint.x, y: currentPoint.y)
    }

    private var clampedProgress: CGFloat {
        return min(max(progress, 0), 1)
    }

    private var currentScale: CGFloat {
        return startScale + (endScale - startScale) * clampedProgress
    }

    /// The point on the arc for the current progress.
    private var currentPoint: CGPoint {
        let t: CGFloat = clampedProgress
        let from = CGPoint(x: start.midX, y: start.midY)
        let to = CGPoint(x: end.midX, y: end.midY)
        let control = CGPoint(
            x: (from.x + to.x) / 2,
            y: min(from.y, to.y) - FlightPathModifier.lift
        )
        let remaining: CGFloat = 1 - t
        let x: CGFloat = remaining * remaining * from.x + 2 * remaining * t * control.x + t * t * to.x
        let y: CGFloat = remaining * remaining * from.y + 2 * remaining * t * control.y + t * t * to.y
        return CGPoint(x: x, y: y)
    }
}
