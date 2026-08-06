import AppKit
import SwiftUI
import TokenBarCore

@main
struct TokenBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(preferences: appDelegate.container.preferences)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let container = AppContainer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apple Silicon + macOS 26 only (true Liquid Glass).
        guard PlatformRequirements.enforceOrQuit() else { return }

        if let icon = AppIconImage.aboutImage() {
            NSApp.applicationIconImage = icon
        }

        // Defer one tick so NSStatusBar is ready under SwiftUI App lifecycle.
        DispatchQueue.main.async { [weak self] in
            self?.container.start()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
