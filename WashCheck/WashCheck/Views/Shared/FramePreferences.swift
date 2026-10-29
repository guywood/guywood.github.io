import SwiftUI

/// Keys for the frames the Load screen needs in order to fly a card into (or out of) the porthole.
enum FrameKey: Hashable, Sendable {
    case porthole
    case card(UUID)
}

enum FrameSpace {
    /// Name of the coordinate space the Load screen declares on its root container.
    /// Every reported frame is expressed in this space, so scrolling is accounted for.
    static let name = "loadScreen"
}

/// Collects `[FrameKey: CGRect]` from descendants.
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [FrameKey: CGRect] { return [:] }

    static func reduce(value: inout [FrameKey: CGRect], nextValue: () -> [FrameKey: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Reports this view's frame, in the Load screen's named coordinate space, under `key`.
    func reportFrame(_ key: FrameKey) -> some View {
        return background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FramePreferenceKey.self,
                    value: [key: proxy.frame(in: .named(FrameSpace.name))]
                )
            }
        )
    }
}
