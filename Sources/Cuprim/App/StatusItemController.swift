import AppKit
import SwiftUI
import CuprimCore

/// Menu-bar extra with a **native NSMenu** (ChatGPT / SuperCmd style).
/// Click the gauge → system menu. Full glass dashboard via “Show Cuprim”.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let usage: UsageStore
    private let preferences: PreferencesStore
    private let panel: PanelController
    private let menu = NSMenu()

    init(
        usage: UsageStore,
        preferences: PreferencesStore,
        panel: PanelController
    ) {
        self.usage = usage
        self.preferences = preferences
        self.panel = panel

        self.statusItem = NSStatusBar.system.statusItem(withLength: 28)
        self.statusItem.isVisible = true

        super.init()

        configureButton()
        configureMenu()
        reloadTitle()
        NSLog("[Cuprim] status item created (native menu)")
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            NSLog("[Cuprim] FATAL: status item button is nil")
            return
        }

        let image = Self.menuBarTemplateImage()
        button.image = image
        button.imagePosition = .imageOnly
        button.isEnabled = true
        button.appearsDisabled = false
        button.toolTip = "Cuprim"
        button.title = ""
        // Native menu owns clicks — same pattern as ChatGPT / SuperCmd.
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.autoenablesItems = false
        menu.delegate = self
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // Close glass panel if open so only one surface is visible.
        if panel.isVisible {
            panel.hide()
        }
    }

    /// Single rebuild site — avoid double rebuild with `menuWillOpen`.
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    /// Rebuild menu contents (usage + actions) every open.
    private func rebuildMenu() {
        menu.removeAllItems()

        // —— Usage (like ChatGPT “Usage” block) ——
        let usageHeader = NSMenuItem(title: "Usage", action: nil, keyEquivalent: "")
        usageHeader.isEnabled = false
        menu.addItem(usageHeader)

        let snapshots = usage.visibleSnapshots
        if snapshots.isEmpty {
            let empty = NSMenuItem(
                title: usage.isRefreshing ? "Loading…" : "No providers signed in",
                action: nil,
                keyEquivalent: ""
            )
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for snap in snapshots {
                menu.addItem(usageItem(for: snap))
            }
        }

        menu.addItem(.separator())

        // —— Actions (SuperCmd style) ——
        let show = NSMenuItem(
            title: "Show Cuprim",
            action: #selector(showDashboard),
            keyEquivalent: ""
        )
        show.target = self
        menu.addItem(show)

        let refresh = NSMenuItem(
            title: usage.isRefreshing ? "Refreshing…" : "Refresh",
            action: #selector(refresh),
            keyEquivalent: "r"
        )
        refresh.keyEquivalentModifierMask = [.command]
        refresh.target = self
        refresh.isEnabled = !usage.isRefreshing
        menu.addItem(refresh)

        let settings = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settings.keyEquivalentModifierMask = [.command]
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let share = NSMenuItem(
            title: "Share Screenshot",
            action: nil,
            keyEquivalent: ""
        )
        share.submenu = shareScreenshotSubmenu()
        menu.addItem(share)

        let about = NSMenuItem(
            title: "About Cuprim",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let updates = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updates.target = self
        menu.addItem(updates)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit Cuprim",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.keyEquivalentModifierMask = [.command]
        quit.target = self
        menu.addItem(quit)
    }

    private func shareScreenshotSubmenu() -> NSMenu {
        let sub = NSMenu(title: "Share Screenshot")
        // Each item = one provider card (not "open destination with all tabs").
        for id in preferences.orderedProviders where preferences.isEnabled(id) {
            let item = NSMenuItem(
                title: id.displayName,
                action: #selector(shareScreenshot(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.image = Self.menuImage(for: id)
            item.representedObject = id.rawValue
            sub.addItem(item)
        }
        return sub
    }

    /// One row per provider — title + subtitle (ChatGPT-style).
    private func usageItem(for snap: ProviderSnapshot) -> NSMenuItem {
        let item = NSMenuItem(
            title: usageTitle(for: snap),
            action: #selector(showDashboard),
            keyEquivalent: ""
        )
        item.target = self
        item.subtitle = usageSubtitle(for: snap)
        item.image = Self.menuImage(for: snap.id)
        item.representedObject = snap.id.rawValue
        return item
    }

    private func usageTitle(for snap: ProviderSnapshot) -> String {
        if let plan = snap.planName, !plan.isEmpty {
            return "\(snap.id.displayName) · \(plan)"
        }
        return snap.id.displayName
    }

    private func usageSubtitle(for snap: ProviderSnapshot) -> String {
        switch snap.status {
        case .notLoggedIn:
            return "Not signed in"
        case .error(let message):
            return message
        case .ok:
            guard let worst = snap.metrics.compactMap(\.usedFraction).max() else {
                return "No metrics"
            }
            // Keep the status menu narrow: short % + relative reset only (no absolute dates).
            let used = QuotaFormatting.usedPercentLabel(usedFraction: worst)
            let nextReset = snap.metrics.compactMap(\.resetsAt).sorted().first
            let label = QuotaFormatting.resetLabel(for: nextReset, absolute: false)
            if !label.isEmpty {
                let short = label
                    .replacingOccurrences(of: "Resets in ", with: "")
                    .replacingOccurrences(of: "Resets ", with: "")
                return "\(used) · \(short)"
            }
            return "\(used) used"
        }
    }

    private static func menuImage(for id: ProviderID) -> NSImage? {
        if let custom = ProviderIconView.templateImage(for: id) {
            let img = custom.copy() as? NSImage ?? custom
            img.isTemplate = true
            img.size = NSSize(width: 16, height: 16)
            return img
        }
        if let image = NSImage(systemSymbolName: id.systemImage, accessibilityDescription: id.displayName) {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let configured = image.withSymbolConfiguration(config) ?? image
            configured.isTemplate = true
            return configured
        }
        return nil
    }

    /// Custom gauge template (black on transparent). Falls back to SF Symbol if assets missing.
    private static func menuBarTemplateImage() -> NSImage {
        if let custom = loadMenuBarTemplate() {
            return custom
        }
        return menuBarSymbolFallback()
    }

    private static func loadMenuBarTemplate() -> NSImage? {
        // Prefer @2x / @3x via AppResources; representations keep correct pixel density.
        guard let base = AppResources.image(name: "MenuBarIcon", subdirectory: "MenuBar")
            ?? AppResources.image(name: "MenuBarIcon-16", subdirectory: "MenuBar")
        else { return nil }

        let image = base.copy() as? NSImage ?? base
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    private static func menuBarSymbolFallback() -> NSImage {
        let names = [AppSymbols.app, AppSymbols.appFallback, "chart.bar.fill", "circle.fill"]
        for name in names {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: "Cuprim") {
                let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                let configured = image.withSymbolConfiguration(config) ?? image
                configured.isTemplate = true
                configured.size = NSSize(width: 18, height: 18)
                return configured
            }
        }
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: 14, height: 14), xRadius: 3, yRadius: 3).fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    // MARK: - Actions

    @objc private func showDashboard() {
        guard let button = statusItem.button else { return }
        // Clear menu briefly so the panel can take focus (menu dismisses first).
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.panel.show(relativeTo: button)
        }
    }

    @objc private func refresh() {
        Task { await usage.refresh() }
    }

    @objc private func openSettings() {
        SettingsOpener.open()
    }

    @objc private func openAbout() {
        AboutWindowController.show()
    }

    @objc private func checkForUpdates() {
        OpenSourceInfo.checkForUpdates()
    }

    @objc private func shareScreenshot(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let providerID = ProviderID(rawValue: raw),
              let target = ScreenshotShare.Target(rawValue: raw)
        else { return }

        // Render after the status menu closes so pasteboard write isn't interrupted.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let snapshot = self.usage.snapshots[providerID]
                ?? ProviderSnapshot.empty(providerID, status: .notLoggedIn)
            let cards = [snapshot]
            guard let image = ShareCardView.renderImage(
                snapshots: cards,
                showUsedPercent: self.preferences.showUsedPercent
            ) else {
                NSSound.beep()
                return
            }
            let summary = ScreenshotShare.usageSummary(
                from: cards,
                showUsed: self.preferences.showUsedPercent
            )
            ScreenshotShare.share(image: image, summary: summary, to: target)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func reloadTitle() {
        guard let button = statusItem.button else { return }
        if button.image == nil {
            button.image = Self.menuBarTemplateImage()
        }
        button.isEnabled = true
        button.appearsDisabled = false
        statusItem.isVisible = true
        button.imagePosition = .imageOnly
        button.title = ""
        statusItem.length = 28
        if let remaining = usage.worstRemainingPercent {
            button.toolTip = "Cuprim · \(remaining)% remaining"
        } else {
            button.toolTip = "Cuprim"
        }
    }
}
