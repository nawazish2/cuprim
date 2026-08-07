import AppKit

/// Opens the SwiftUI Settings scene (⌘,). Avoids a second custom window that can render blank.
@MainActor
enum SettingsOpener {
    static func open() {
        NSApp.activate(ignoringOtherApps: true)
        // Standard selector used by SwiftUI `Settings` scenes on macOS.
        let opened = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        if !opened {
            // Fallback if the Settings scene is unavailable for any reason.
            if let prefs = (NSApp.delegate as? AppDelegate)?.container.preferences {
                let usage = (NSApp.delegate as? AppDelegate)?.container.usage
                SettingsWindowController.show(preferences: prefs, usage: usage)
            }
        }
    }
}
