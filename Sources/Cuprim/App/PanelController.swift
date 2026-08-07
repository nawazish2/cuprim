import AppKit
import SwiftUI
import CuprimCore

@MainActor
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private var panel: KeyablePanel?
    private var hosting: NSHostingController<DashboardView>?
    private let usage: UsageStore
    private let preferences: PreferencesStore
    private let uiState: DashboardUIState
    private let onOpenSettings: () -> Void
    private let onQuit: () -> Void
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private weak var statusButton: NSStatusBarButton?

    private let contentSize = NSSize(
        width: GlassChrome.panelWidth + GlassChrome.outerPad * 2,
        height: GlassChrome.panelHeight + GlassChrome.outerPad * 2
    )

    init(
        usage: UsageStore,
        preferences: PreferencesStore,
        uiState: DashboardUIState,
        onOpenSettings: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.usage = usage
        self.preferences = preferences
        self.uiState = uiState
        self.onOpenSettings = onOpenSettings
        self.onQuit = onQuit
        super.init()
    }

    var isVisible: Bool { panel?.isVisible == true }

    /// Snapshot the glass dashboard for Share Screenshot.
    func snapshotImage() -> NSImage? {
        if let view = hosting?.view ?? panel?.contentView {
            return view.cuprimSnapshotImage()
        }
        return nil
    }

    /// Ensure the panel is built/shown so a snapshot has real content.
    func prepareForSnapshot(relativeTo statusButton: NSStatusBarButton) {
        show(relativeTo: statusButton)
        // Give SwiftUI one turn to lay out before bitmap capture.
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    func toggle(relativeTo statusButton: NSStatusBarButton) {
        self.statusButton = statusButton
        if isVisible { hide() } else { show(relativeTo: statusButton) }
    }

    func show(relativeTo statusButton: NSStatusBarButton) {
        self.statusButton = statusButton
        let panel = ensurePanel()

        let root = DashboardView(
            usage: usage,
            preferences: preferences,
            uiState: uiState,
            onOpenSettings: { [weak self] in
                self?.hide()
                self?.onOpenSettings()
            },
            onQuit: onQuit
        )

        if let hosting {
            hosting.rootView = root
            hosting.view.frame = NSRect(origin: .zero, size: contentSize)
        } else {
            let controller = NSHostingController(rootView: root)
            controller.view.frame = NSRect(origin: .zero, size: contentSize)
            controller.sizingOptions = []
            controller.view.wantsLayer = true
            controller.view.layer?.backgroundColor = NSColor.clear.cgColor
            controller.view.layer?.masksToBounds = true
            panel.contentViewController = controller
            hosting = controller
        }

        panel.setContentSize(contentSize)
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.masksToBounds = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        position(panel, relativeTo: statusButton)
        panel.orderFrontRegardless()
        panel.makeKey()
        installDismissMonitor()
    }

    func hide() {
        panel?.orderOut(nil)
        removeDismissMonitor()
    }

    private func position(_ panel: KeyablePanel, relativeTo statusButton: NSStatusBarButton) {
        guard let buttonWindow = statusButton.window else { return }
        let buttonRect = statusButton.convert(statusButton.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        var x = screenRect.midX - contentSize.width / 2
        var y = screenRect.minY - contentSize.height - 8

        if let screen = buttonWindow.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            x = min(max(x, visible.minX + 8), visible.maxX - contentSize.width - 8)
            if y < visible.minY + 8 {
                y = screenRect.maxY + 8
            }
            y = min(max(y, visible.minY + 8), visible.maxY - contentSize.height - 8)
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func ensurePanel() -> KeyablePanel {
        if let panel { return panel }

        let panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        // Needed for SwiftUI .onHover (blue menu highlight).
        panel.acceptsMouseMovedEvents = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.delegate = self
        self.panel = panel
        return panel
    }

    private func clickIsOnStatusItem(_ event: NSEvent) -> Bool {
        guard let button = statusButton, let window = button.window else { return false }
        return window.frame.insetBy(dx: -6, dy: -6).contains(NSEvent.mouseLocation)
    }

    private func installDismissMonitor() {
        removeDismissMonitor()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible else { return event }
            if event.type == .keyDown, event.keyCode == 53 { // Escape
                self.hide()
                return nil
            }
            if event.type == .leftMouseDown || event.type == .rightMouseDown {
                if event.window != panel, !self.clickIsOnStatusItem(event) {
                    self.hide()
                }
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return }
            if self.clickIsOnStatusItem(event) { return }
            self.hide()
        }
    }

    private func removeDismissMonitor() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }
}
