import AppKit
import SwiftUI
import CuprimCore

/// Dedicated Settings window (do not use SwiftUI `Settings` scene from the status item).
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: SettingsWindowController?
    private var didEnterActivation = false
    private var hosting: NSHostingController<SettingsView>?

    static func show(preferences: PreferencesStore) {
        // Fresh controller if the previous window was released.
        if let existing = shared, existing.window == nil {
            shared = nil
        }

        let controller: SettingsWindowController
        if let existing = shared {
            existing.hosting?.rootView = SettingsView(preferences: preferences)
            controller = existing
        } else {
            controller = SettingsWindowController(preferences: preferences)
            shared = controller
        }

        AppActivationPolicy.enter()
        controller.didEnterActivation = true

        guard let window = controller.window else {
            NSLog("[Cuprim] Settings: window is nil")
            return
        }

        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.level = .floating
        // Drop back to normal after a tick so it doesn't stay above everything forever.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            window.level = .normal
        }

        if window.frame.size.width < 50 || window.frame.size.height < 50 {
            window.setContentSize(NSSize(width: 400, height: 480))
            window.center()
        }

        window.center()
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSLog(
            "[Cuprim] Settings shown frame=%@ visible=%d key=%d",
            NSStringFromRect(window.frame),
            window.isVisible ? 1 : 0,
            window.isKeyWindow ? 1 : 0
        )
    }

    private init(preferences: PreferencesStore) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        super.init(window: window)
        configure(preferences: preferences)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(preferences: PreferencesStore) {
        guard let window else { return }
        window.title = "Cuprim Settings"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.hasShadow = true
        window.hidesOnDeactivate = false
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.delegate = self

        let root = SettingsView(preferences: preferences)
        let controller = NSHostingController(rootView: root)
        controller.sizingOptions = []
        controller.view.frame = NSRect(x: 0, y: 0, width: 400, height: 480)
        controller.view.wantsLayer = true
        window.contentViewController = controller
        hosting = controller
        window.setContentSize(NSSize(width: 400, height: 480))
        window.center()
    }

    func windowWillClose(_ notification: Notification) {
        if didEnterActivation {
            AppActivationPolicy.leave()
            didEnterActivation = false
        }
    }
}
