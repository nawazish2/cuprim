import AppKit
import Foundation
import CuprimCore

@MainActor
enum SettingsOpener {
    /// Presents the Settings window. Dependencies are passed in rather than
    /// held statically: the previous version cached them in `static var`s and
    /// fell back to `AppDelegate.shared`, so the same three objects had two
    /// sources of truth and "no preferences; cannot open" was a reachable state.
    static func open(
        preferences: PreferencesStore,
        usage: UsageStore?,
        notifications: NotificationCoordinator?
    ) {
        // Deferred twice: off this run-loop turn so a hiding panel finishes,
        // then a short beat so key-window handoff is clean.
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSLog("[Cuprim] Settings: presenting…")
                SettingsWindowController.show(
                    preferences: preferences,
                    usage: usage,
                    notifications: notifications
                )
            }
        }
    }
}
