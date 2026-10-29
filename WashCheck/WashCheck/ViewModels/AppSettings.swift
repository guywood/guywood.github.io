import Foundation

/// `UserDefaults` keys for the handful of user preferences, shared by `@AppStorage` and `Haptics`.
enum SettingsKeys {
    static let hapticsEnabled = "settings.hapticsEnabled"
    static let showNumericScores = "settings.showNumericScores"
}

enum AppSettings {
    /// Registers the default values so reads before the Settings screen is ever opened are correct.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            SettingsKeys.hapticsEnabled: true,
            SettingsKeys.showNumericScores: false,
        ])
    }

    /// Current value of the haptics preference, defaulting to on.
    static var hapticsEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: SettingsKeys.hapticsEnabled) == nil { return true }
        return defaults.bool(forKey: SettingsKeys.hapticsEnabled)
    }

    /// Current value of the numeric-score preference, defaulting to off.
    static var showNumericScores: Bool {
        return UserDefaults.standard.bool(forKey: SettingsKeys.showNumericScores)
    }
}
