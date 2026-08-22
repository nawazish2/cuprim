import AppKit
import CuprimCore

/// Keeps the menu-bar app out of the Dock until a real window is open.
///
/// Settings and About can overlap, so activation is reference counted. The
/// policy only returns to `.accessory` once the last owned window closes.
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
        guard count == 0 else { return }
        // Let AppKit finish the close transaction before changing activation
        // policy; doing this synchronously can strand the closing window.
        DispatchQueue.main.async { @MainActor in
            guard count == 0 else { return }
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
