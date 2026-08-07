import AppKit

/// Opens Settings for the menu-bar app via a dedicated `NSWindow`.
/// Menu tracking often swallows synchronous presents — always defer past dismiss.
@MainActor
enum SettingsOpener {
    private static var preferences: PreferencesStore?

    static func configure(preferences: PreferencesStore, usage _: UsageStore? = nil) {
        self.preferences = preferences
    }

    /// Call from status menus / panel. Always deferred so the window can appear.
    static func open(preferences: PreferencesStore? = nil) {
        if let preferences {
            self.preferences = preferences
        }
        // Status-item menus finish dismissing after the next few runloop passes.
        DispatchQueue.main.async {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                Self.present()
            }
        }
    }

    private static func present() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let prefs = preferences ?? AppDelegate.shared?.container.preferences
        guard let prefs else {
            NSLog("[Cuprim] Settings: no preferences; cannot open")
            return
        }

        NSLog("[Cuprim] Settings: presenting…")
        SettingsWindowController.show(preferences: prefs)
    }
}
