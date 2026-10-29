import Foundation

/// The glyph shown on an item card: either an emoji or an SF Symbol name.
///
/// Stored as a single string (`"e:👕"` or `"s:tshirt"`) so SwiftData only needs one column.
enum ItemIcon: Hashable, Sendable {
    case emoji(String)
    case symbol(String)

    static let defaultIcon = ItemIcon.emoji("👕")

    /// The string persisted in the database.
    var storageValue: String {
        switch self {
        case .emoji(let value): return "e:" + value
        case .symbol(let name): return "s:" + name
        }
    }

    /// Rebuilds an icon from its storage string. Unknown prefixes are treated as an emoji.
    init(storageValue: String) {
        if storageValue.hasPrefix("e:") {
            self = .emoji(String(storageValue.dropFirst(2)))
        } else if storageValue.hasPrefix("s:") {
            self = .symbol(String(storageValue.dropFirst(2)))
        } else if storageValue.isEmpty {
            self = ItemIcon.defaultIcon
        } else {
            self = .emoji(storageValue)
        }
    }

    /// Whether this is an emoji glyph (as opposed to an SF Symbol).
    var isEmoji: Bool {
        if case .emoji = self { return true }
        return false
    }

    /// Emoji offered in the icon picker, clothing and laundry first.
    static let curatedEmoji: [String] = [
        "👕", "👚", "👖", "🧥", "👗", "👔", "🩳", "🩱", "🩲", "🧦", "🧤", "🧣",
        "🧢", "👒", "🎽", "👘", "🥻", "🩴", "👟", "🛏️", "🛁", "🧺", "🧶", "🧸",
        "🛋️", "🏃", "⚽", "🎒", "🧽", "🪢", "🌸", "⭐",
    ]

    /// SF Symbols offered in the icon picker. All names exist in iOS 17.
    static let curatedSymbols: [String] = [
        "tshirt", "tshirt.fill", "hanger", "washer", "dryer", "bed.double",
        "bed.double.fill", "figure.run", "figure.walk", "shoe.fill", "sparkles",
        "drop.fill", "leaf", "sun.max", "snowflake", "heart.fill", "star.fill",
        "scissors", "bag.fill", "moon.fill", "tag", "square.stack.3d.up",
    ]
}
