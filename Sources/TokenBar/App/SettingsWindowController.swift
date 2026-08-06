import AppKit
import SwiftUI
import TokenBarCore

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: SettingsWindowController?
    private let preferences: PreferencesStore
    private var didEnterActivation = false

    static func show(preferences: PreferencesStore) {
        if shared == nil {
            shared = SettingsWindowController(preferences: preferences)
        } else {
            // Refresh root view so preference bindings stay live.
            shared?.hosting?.rootView = SettingsView(preferences: preferences)
        }
        shared?.showWindow(nil)
    }

    private var hosting: NSHostingController<SettingsView>?

    private init(preferences: PreferencesStore) {
        self.preferences = preferences
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard let window else { return }
        window.title = "TokenBar Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.center()
        window.delegate = self

        let controller = NSHostingController(rootView: SettingsView(preferences: preferences))
        window.contentViewController = controller
        hosting = controller
        window.setContentSize(NSSize(width: 380, height: 420))
    }

    override func showWindow(_ sender: Any?) {
        let wasVisible = window?.isVisible == true
        super.showWindow(sender)
        if !wasVisible, !didEnterActivation {
            AppActivationPolicy.enter()
            didEnterActivation = true
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if didEnterActivation {
            AppActivationPolicy.leave()
            didEnterActivation = false
        }
    }
}
