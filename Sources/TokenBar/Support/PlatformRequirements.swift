import AppKit
import Foundation
import TokenBarCore

/// TokenBar requires Apple Silicon + macOS 26+ for true Liquid Glass.
enum PlatformRequirements {
    static var isAppleSilicon: Bool {
        #if arch(arm64)
        true
        #else
        false
        #endif
    }

    static var isSupportedOS: Bool {
        if #available(macOS 26.0, *) {
            return true
        }
        return false
    }

    static var isSupported: Bool {
        isAppleSilicon && isSupportedOS
    }

    /// Call at launch. Shows an alert and returns `false` when the Mac is unsupported.
    @MainActor
    @discardableResult
    static func enforceOrQuit() -> Bool {
        guard isSupported else {
            presentUnsupportedAlert()
            NSApp.terminate(nil)
            return false
        }
        return true
    }

    @MainActor
    private static func presentUnsupportedAlert() {
        let alert = NSAlert()
        alert.messageText = "TokenBar can’t run on this Mac"
        if !isAppleSilicon {
            alert.informativeText = "TokenBar requires an Apple Silicon Mac (M1 or later)."
        } else {
            alert.informativeText = "TokenBar requires macOS 26 or later for Liquid Glass."
        }
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
