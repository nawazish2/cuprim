import AppKit
import CuprimCore

/// Keeps the app activatable for Settings / windows.
/// Dock icon stays visible (app runs as `.regular`); we only activate, never demote to accessory.
@MainActor
enum AppActivationPolicy {
    private static var count = 0

    static func enter() {
        count += 1
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func leave() {
        count = max(0, count - 1)
        // Stay `.regular` so the Dock icon remains. Menu bar apps that hide from
        // Dock would set `.accessory` here — Cuprim shows both.
    }
}
