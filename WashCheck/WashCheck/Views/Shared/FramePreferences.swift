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

/// Holds the latest reported frames without being observable, so scrolling (which changes every
/// card's frame) never re-renders the Load screen. It is read when a tap starts a flight.
final class FrameStore {
    private(set) var frames: [FrameKey: CGRect] = [:]

    func update(_ frames: [FrameKey: CGRect]) {
        self.frames = frames
    }

    func frame(for key: FrameKey) -> CGRect? {
        return frames[key]
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
