import AppKit
import SwiftUI
import CuprimCore

/// Fallback Settings window when the SwiftUI Settings scene cannot open.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: SettingsWindowController?
    private let preferences: PreferencesStore
    private let usage: UsageStore?
    private var didEnterActivation = false
    private var hosting: NSHostingController<SettingsView>?

    static func show(preferences: PreferencesStore, usage: UsageStore? = nil) {
        if shared == nil {
            shared = SettingsWindowController(preferences: preferences, usage: usage)
        } else {
            shared?.hosting?.rootView = SettingsView(preferences: preferences, usage: usage)
        }
        shared?.showWindow(nil)
    }

    private init(preferences: PreferencesStore, usage: UsageStore?) {
        self.preferences = preferences
        self.usage = usage
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 460),
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
        window.title = "Cuprim Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.center()
        window.delegate = self

        let root = SettingsView(preferences: preferences, usage: usage)
        let controller = NSHostingController(rootView: root)
        controller.sizingOptions = [.preferredContentSize]
        window.contentViewController = controller
        hosting = controller

        let size = controller.sizeThatFits(in: NSSize(width: 400, height: 2000))
        let fitted = NSSize(width: 400, height: min(max(size.height, 420), 640))
        window.setContentSize(fitted)
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
