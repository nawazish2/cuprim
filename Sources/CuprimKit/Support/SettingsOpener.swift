import AppKit
import Foundation
import CuprimCore

@MainActor
enum SettingsOpener {
    private static var preferences: PreferencesStore?
    private static var usage: UsageStore?
    private static var notifications: NotificationCoordinator?

    static func configure(
        preferences: PreferencesStore,
        usage: UsageStore? = nil,
        notifications: NotificationCoordinator? = nil
    ) {
        self.preferences = preferences
        self.usage = usage
        self.notifications = notifications
    }

    static func open(preferences: PreferencesStore? = nil) {
        if let preferences {
            self.preferences = preferences
        }
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                Self.present()
            }
        }
    }

    private static func present() {
        let prefs = preferences ?? AppDelegate.shared?.container.preferences
        guard let prefs else {
            NSLog("[Cuprim] Settings: no preferences; cannot open")
            return
        }
        NSLog("[Cuprim] Settings: presenting…")
        SettingsWindowController.show(
            preferences: prefs,
            usage: usage ?? AppDelegate.shared?.container.usage,
            notifications: notifications ?? AppDelegate.shared?.container.notifications
        )
    }
}
