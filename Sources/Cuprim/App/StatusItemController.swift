import AppKit
import SwiftUI
import CuprimCore

/// Menu-bar extra with a **native NSMenu**.
/// Template cup by default; badges for exceptional status; temporary refresh arc.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let usage: UsageStore
    private let preferences: PreferencesStore
    private let uiState: DashboardUIState
    private let panel: PanelController
    private let menu = NSMenu()

    private var refreshTimer: Timer?
    private var refreshPhase: CGFloat = 0
    private var appearanceObserver: NSObjectProtocol?

    init(
        usage: UsageStore,
        preferences: PreferencesStore,
        uiState: DashboardUIState,
        panel: PanelController
    ) {
        self.usage = usage
        self.preferences = preferences
        self.uiState = uiState
        self.panel = panel

        self.statusItem = NSStatusBar.system.statusItem(withLength: 26)
        self.statusItem.isVisible = true

        super.init()

        configureButton()
        configureMenu()
        observeAppearance()
        reloadTitle()
        NSLog("[Cuprim] status item created (native menu · template icon)")
    }

    deinit {
        // Timer / observer cleanup via stopRefreshAnimation + removeObserver is done on main;
        // NSStatusItem is released with the controller.
    }

    private func configureButton() {
        guard let button = statusItem.button else {
            NSLog("[Cuprim] FATAL: status item button is nil")
            return
        }

        button.image = MenuBarIcon.image(kind: .idle)
        button.imagePosition = .imageOnly
        button.isEnabled = true
        button.appearsDisabled = false
        button.toolTip = "Cuprim"
        button.title = ""
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.autoenablesItems = false
        menu.delegate = self
    }

    private func observeAppearance() {
        // Rebuild composed badge glyphs when light/dark flips (labelColor changes).
        appearanceObserver = DistributedNotificationCenter.default.addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reloadTitle()
            }
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        if panel.isVisible {
            panel.hide()
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        // Pre–status-chip layout: “Usage” block, title + subtitle per provider.
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

        let show = NSMenuItem(
            title: "Show Cuprim",
            action: #selector(showOverviewDashboard),
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
        settings.image = nil
        menu.addItem(settings)

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

    /// ChatGPT-style row (pre–color-dot chips): title + monochrome subtitle.
    private func usageItem(for snap: ProviderSnapshot) -> NSMenuItem {
        let item = NSMenuItem(
            title: usageTitle(for: snap),
            action: #selector(showProviderDashboard(_:)),
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
            return message.isEmpty ? "Unavailable" : message
        case .ok:
            guard let worst = snap.worstUsedFraction else {
                return "No metrics"
            }
            if worst >= 0.95 {
                return "Limit Reached"
            }
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

    // MARK: - Actions

    @objc private func showOverviewDashboard() {
        openDashboard(tab: .overview)
    }

    func showDashboardFromNotification() {
        openDashboard(tab: .overview)
    }

    @objc private func showProviderDashboard(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String,
           let id = ProviderID(rawValue: raw) {
            openDashboard(tab: .provider(id))
        } else {
            openDashboard(tab: .overview)
        }
    }

    private func openDashboard(tab: ProviderTab) {
        guard let button = statusItem.button else { return }
        uiState.selectedTab = tab
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.panel.show(relativeTo: button)
        }
    }

    @objc private func refresh() {
        Task { await usage.refresh() }
    }

    @objc private func openSettings() {
        panel.hide()
        NSLog("[Cuprim] Settings menu action")
        // Pass preferences directly — don't rely only on static configure.
        SettingsOpener.open(preferences: preferences)
    }

    @objc private func checkForUpdates() {
        OpenSourceInfo.checkForUpdates()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: - Status item image

    func reloadTitle() {
        guard let button = statusItem.button else { return }

        let kind = MenuBarIcon.resolve(usage: usage)
        syncRefreshAnimation(isRefreshing: kind == .refreshing)

        let image: NSImage
        if kind == .refreshing {
            image = MenuBarIcon.image(kind: .refreshing, refreshPhase: refreshPhase)
        } else {
            image = MenuBarIcon.image(kind: kind)
        }

        button.image = image
        button.isEnabled = true
        button.appearsDisabled = false
        statusItem.isVisible = true
        button.imagePosition = .imageOnly
        button.title = ""
        statusItem.length = 26

        var tip = "Cuprim"
        if kind == .refreshing {
            if let remaining = usage.worstRemainingPercent {
                tip = "Cuprim · \(remaining)% remaining · Refreshing"
            } else {
                tip = "Cuprim · Refreshing"
            }
        } else if let remaining = usage.worstRemainingPercent {
            tip = "Cuprim · \(remaining)% remaining"
            if let suffix = MenuBarIcon.tooltipSuffix(for: kind) {
                tip += " · \(suffix)"
            }
        } else if let suffix = MenuBarIcon.tooltipSuffix(for: kind) {
            tip = "Cuprim · \(suffix)"
        }
        button.toolTip = tip
    }

    private func syncRefreshAnimation(isRefreshing: Bool) {
        if isRefreshing {
            guard refreshTimer == nil else { return }
            refreshPhase = 0
            let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    // ~0.45s per full turn: 0.05 * 20 ≈ 1.0 → map to 1.0 phase
                    self.refreshPhase = (self.refreshPhase + 0.05 / 0.45).truncatingRemainder(dividingBy: 1.0)
                    guard let button = self.statusItem.button, self.usage.isRefreshing else {
                        self.stopRefreshAnimation()
                        self.reloadTitle()
                        return
                    }
                    button.image = MenuBarIcon.image(kind: .refreshing, refreshPhase: self.refreshPhase)
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            refreshTimer = timer
        } else {
            stopRefreshAnimation()
        }
    }

    private func stopRefreshAnimation() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        refreshPhase = 0
    }
}
