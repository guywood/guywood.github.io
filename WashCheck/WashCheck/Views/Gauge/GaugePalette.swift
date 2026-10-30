import SwiftUI

/// Colours for the concern gauge and the level labels: green → yellow-green → amber → red.
///
/// The continuous colour is a plain sRGB interpolation between four anchors, so it works on
/// iOS 17 without `Color.mix`. The per-level colours are slightly deeper versions of the same
/// hues so that text labels stay legible on light and dark backgrounds.
enum GaugePalette {

    /// One anchor of the gradient, in sRGB.
    private struct Stop {
        let position: Double
        let red: Double
        let green: Double
        let blue: Double

        var color: Color {
            return Color(red: red, green: green, blue: blue)
        }
    }

    /// Gradient anchors from safe (0) to don't-wash-together (1).
    private static let stops: [Stop] = [
        Stop(position: 0.00, red: 0.20, green: 0.72, blue: 0.36),
        Stop(position: 0.34, red: 0.62, green: 0.78, blue: 0.22),
        Stop(position: 0.67, red: 0.96, green: 0.62, blue: 0.11),
        Stop(position: 1.00, red: 0.86, green: 0.20, blue: 0.22),
    ]

    /// Continuous colour for a 0...1 fraction: green → yellow-green → amber → red.
    /// Pure RGB interpolation between the stops; values outside 0...1 are clamped.
    static func color(for fraction: Double) -> Color {
        let clamped: Double = min(1.0, max(0.0, fraction))
        guard let first = stops.first, let last = stops.last else {
            return Color.green
        }
        if clamped <= first.position {
            return first.color
        }
        if clamped >= last.position {
            return last.color
        }

        var lower: Stop = first
        var upper: Stop = last
        for index in 1..<stops.count {
            if clamped <= stops[index].position {
                lower = stops[index - 1]
                upper = stops[index]
                break
            }
        }

        let span: Double = upper.position - lower.position
        let t: Double = span > 0 ? (clamped - lower.position) / span : 0
        let red: Double = lower.red + (upper.red - lower.red) * t
        let green: Double = lower.green + (upper.green - lower.green) * t
        let blue: Double = lower.blue + (upper.blue - lower.blue) * t
        return Color(red: red, green: green, blue: blue)
    }

    /// The band colour used for labels and the machine's indicator lights.
    static func color(for level: ConcernLevel) -> Color {
        switch level {
        case .safe:
            return Color(red: 0.16, green: 0.62, blue: 0.33)
        case .mildCaution:
            return Color(red: 0.55, green: 0.66, blue: 0.12)
        case .caution:
            return Color(red: 0.88, green: 0.52, blue: 0.05)
        case .dontWashTogether:
            return Color(red: 0.80, green: 0.16, blue: 0.20)
        }
    }
}
