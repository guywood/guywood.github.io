import SwiftUI

/// A vertical thermometer that fills to the load's score fraction and changes colour as it rises.
///
/// Intrinsic width is about 90 pt (track plus threshold labels); the height is whatever the
/// parent offers, so the Load screen can give it the same height as the washing machine.
struct ConcernGaugeView: View {
    let assessment: LoadAssessment
    let showNumericScore: Bool
    /// The weights the assessment was produced with; positions the threshold ticks.
    var weights: ScoringWeights = .default

    private let totalWidth: CGFloat = 90
    private let trackWidth: CGFloat = 26
    private let bulbDiameter: CGFloat = 44
    private let topInset: CGFloat = 10
    private let labelWidth: CGFloat = 50

    var body: some View {
        GeometryReader { proxy in
            let height: CGFloat = proxy.size.height
            let fillColor: Color = GaugePalette.color(for: assessment.fraction)
            let trackCenterX: CGFloat = trackWidth / 2 + 2
            let bulbCenterY: CGFloat = height - bulbDiameter / 2 - 2
            let trackHeight: CGFloat = max(0, bulbCenterY - topInset)
            let fillHeight: CGFloat = trackHeight * CGFloat(assessment.fraction)
            let tickX: CGFloat = trackCenterX + trackWidth / 2 + 6
            let labelX: CGFloat = trackCenterX + trackWidth / 2 + 12 + labelWidth / 2

            ZStack(alignment: .topLeading) {
                // Track with the rising fill. The track runs into the bulb so the fill always
                // appears to emerge from it.
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(fillColor)
                        .frame(width: trackWidth - 8, height: fillHeight)
                }
                .frame(width: trackWidth, height: trackHeight)
                .position(x: trackCenterX, y: topInset + trackHeight / 2)

                // Threshold ticks and their short labels.
                ForEach(ConcernLevel.allCases.filter { $0 != .safe }, id: \.self) { level in
                    let tickY: CGFloat = tickPosition(for: level, trackBottom: bulbCenterY, trackHeight: trackHeight)
                    Rectangle()
                        .fill(Color(.tertiaryLabel))
                        .frame(width: 8, height: 1.5)
                        .position(x: tickX, y: tickY)
                    Text(level.shortName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: labelWidth, alignment: .leading)
                        .position(x: labelX, y: tickY)
                }

                // Bulb.
                Circle()
                    .fill(fillColor)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
                    .frame(width: bulbDiameter, height: bulbDiameter)
                    .position(x: trackCenterX, y: bulbCenterY)

                if showNumericScore {
                    Text("\(assessment.score)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                        .frame(width: bulbDiameter - 8, height: bulbDiameter - 8)
                        .position(x: trackCenterX, y: bulbCenterY)
                }
            }
            .animation(.spring(duration: 0.6), value: assessment.score)
        }
        .frame(width: totalWidth)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Concern gauge")
        .accessibilityValue("\(assessment.level.displayName), \(assessment.score) out of \(assessment.maximumScore)")
    }

    /// The y position (in the gauge's own space) of the lowest score that maps to `level`.
    private func tickPosition(for level: ConcernLevel, trackBottom: CGFloat, trackHeight: CGFloat) -> CGFloat {
        let maximum: Int = max(1, assessment.maximumScore)
        let raw: Double = Double(level.lowerBound(weights: weights)) / Double(maximum)
        let fraction: Double = min(1.0, max(0.0, raw))
        return trackBottom - trackHeight * CGFloat(fraction)
    }
}

#Preview {
    HStack(spacing: 24) {
        ConcernGaugeView(assessment: .empty, showNumericScore: true)
        ConcernGaugeView(
            assessment: assessLoad([
                LoadItem(name: "Red hoodie", colourGroup: .reds, fabricWeight: .heavy),
                LoadItem(name: "Lace underwear", colourGroup: .lights, fabricWeight: .delicate),
            ]),
            showNumericScore: true
        )
    }
    .frame(height: 240)
    .padding()
}
