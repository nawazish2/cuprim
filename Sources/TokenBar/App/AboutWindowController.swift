import AppKit
import SwiftUI

@MainActor
final class AboutWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: AboutWindowController?
    private var didEnterActivation = false
    private var hosting: NSHostingController<AboutView>?

    static func show() {
        if shared == nil {
            shared = AboutWindowController()
        }
        shared?.showWindow(nil)
    }

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 360),
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
        window.title = "About TokenBar"
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        window.isOpaque = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.center()
        window.delegate = self

        let controller = NSHostingController(rootView: AboutView())
        // Same sizing pattern as Settings — avoids blank / clipped hosting views.
        controller.sizingOptions = [.preferredContentSize]
        window.contentViewController = controller
        hosting = controller

        let size = controller.sizeThatFits(in: NSSize(width: 320, height: 2000))
        let fitted = NSSize(width: 320, height: min(max(size.height, 360), 480))
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
