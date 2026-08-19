import AppKit
import QuartzCore
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
        onQuit: @escaping () -> Void
    ) {
        self.usage = usage
        self.preferences = preferences
        self.uiState = uiState
        self.onQuit = onQuit
        super.init()
    }

    var isVisible: Bool { panel?.isVisible == true && !isHiding }
    private var isHiding = false

    func toggle(relativeTo statusButton: NSStatusBarButton) {
        self.statusButton = statusButton
        if isVisible { hide() } else { show(relativeTo: statusButton) }
    }

    func show(relativeTo statusButton: NSStatusBarButton) {
        self.statusButton = statusButton
        let panel = ensurePanel()
        uiState.scrollResetToken += 1

        let root = DashboardView(
            usage: usage,
            preferences: preferences,
            uiState: uiState,
            onOpenSettings: { [weak self] in
                // Defer after panel hide so key-window handoff is clean.
                self?.hide()
                SettingsOpener.open()
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
        animateIn(panel)
        installDismissMonitor()
    }

    func hide() {
        guard let panel, panel.isVisible, !isHiding else {
            removeDismissMonitor()
            return
        }
        removeDismissMonitor()
        animateOut(panel)
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private func animateIn(_ panel: KeyablePanel) {
        isHiding = false

        if reduceMotion {
            resetPresentation(panel)
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            panel.makeKey()
            return
        }

        applyScale(0.96, to: panel)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 0.82, 0.24, 1)
            ctx.allowsImplicitAnimation = true
            panel.animator().alphaValue = 1
            applyScale(1, to: panel, animated: true)
        }
    }

    private func animateOut(_ panel: KeyablePanel) {
        if reduceMotion {
            panel.orderOut(nil)
            resetPresentation(panel)
            isHiding = false
            return
        }

        isHiding = true
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            ctx.allowsImplicitAnimation = true
            panel.animator().alphaValue = 0
            applyScale(0.96, to: panel, animated: true)
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                panel.orderOut(nil)
                self.resetPresentation(panel)
                self.isHiding = false
            }
        })
    }

    private func applyScale(_ scale: CGFloat, to panel: KeyablePanel, animated: Bool = false) {
        guard let view = panel.contentView else { return }
        view.wantsLayer = true
        let layer = view.layer
        layer?.anchorPoint = CGPoint(x: 0.5, y: 1)
        layer?.position = CGPoint(x: view.bounds.midX, y: view.bounds.maxY)
        let transform = CATransform3DMakeScale(scale, scale, 1)
        if animated {
            layer?.transform = transform
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer?.transform = transform
            CATransaction.commit()
        }
    }

    private func resetPresentation(_ panel: KeyablePanel) {
        panel.alphaValue = 1
        applyScale(1, to: panel)
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
