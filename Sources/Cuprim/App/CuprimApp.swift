import AppKit
import SwiftUI
import CuprimCore

@main
struct CuprimApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                preferences: appDelegate.container.preferences
            )
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Cuprim") {
                    AboutWindowController.show()
                }
                Button("Check for Updates…") {
                    OpenSourceInfo.checkForUpdates()
                }
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Available without casting `NSApp.delegate` (SwiftUI wraps the adaptor).
    static private(set) var shared: AppDelegate?

    let container = AppContainer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Apple Silicon + macOS 26 only (true Liquid Glass).
        guard PlatformRequirements.enforceOrQuit() else { return }

        if let icon = AppIconImage.aboutImage() {
            NSApp.applicationIconImage = icon
        }

        // Defer one tick so NSStatusBar is ready under SwiftUI App lifecycle.
        DispatchQueue.main.async { [weak self] in
            self?.container.start()
            self?.installAppMenuItems()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        installAppMenuItems()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// SwiftUI `CommandGroup` is unreliable for Settings-only / menu-bar apps —
    /// ensure About + Updates sit at the top of the app menu.
    private func installAppMenuItems() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }

        if let existing = appMenu.items.first(where: { $0.title.hasPrefix("About") }) {
            existing.title = "About Cuprim"
            existing.target = self
            existing.action = #selector(showAbout(_:))
        } else {
            let about = NSMenuItem(
                title: "About Cuprim",
                action: #selector(showAbout(_:)),
                keyEquivalent: ""
            )
            about.target = self
            appMenu.insertItem(about, at: 0)
        }

        let aboutIndex = appMenu.items.firstIndex(where: { $0.title.hasPrefix("About") }) ?? 0

        if let existing = appMenu.items.first(where: { $0.title.hasPrefix("Check for Updates") }) {
            existing.title = "Check for Updates…"
            existing.target = self
            existing.action = #selector(checkForUpdates(_:))
            let currentIndex = appMenu.items.firstIndex(of: existing) ?? aboutIndex + 1
            if currentIndex != aboutIndex + 1 {
                appMenu.removeItem(existing)
                appMenu.insertItem(existing, at: min(aboutIndex + 1, appMenu.items.count))
            }
        } else {
            let updates = NSMenuItem(
                title: "Check for Updates…",
                action: #selector(checkForUpdates(_:)),
                keyEquivalent: ""
            )
            updates.target = self
            appMenu.insertItem(updates, at: min(aboutIndex + 1, appMenu.items.count))
        }

        let updatesIndex = appMenu.items.firstIndex(where: { $0.title.hasPrefix("Check for Updates") })
            ?? aboutIndex + 1
        let sepAt = updatesIndex + 1
        if sepAt >= appMenu.items.count || !appMenu.items[sepAt].isSeparatorItem {
            appMenu.insertItem(.separator(), at: min(sepAt, appMenu.items.count))
        }
    }

    @objc private func showAbout(_ sender: Any?) {
        AboutWindowController.show()
    }

    @objc private func checkForUpdates(_ sender: Any?) {
        OpenSourceInfo.checkForUpdates()
    }
}
