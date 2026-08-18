import AppKit
import SwiftUI
import CuprimCore

/// Menu-bar extra: click the gauge to toggle the glass dashboard.
/// Template icon by default; temporary refresh arc while loading.
@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let usage: UsageStore
    private let uiState: DashboardUIState
    private let panel: PanelController

    private var refreshTimer: Timer?
    private var refreshPhase: CGFloat = 0
    private var appearanceObserver: NSObjectProtocol?

    init(
        usage: UsageStore,
        preferences _: PreferencesStore,
        uiState: DashboardUIState,
        panel: PanelController
    ) {
        self.usage = usage
        self.uiState = uiState
        self.panel = panel

        self.statusItem = NSStatusBar.system.statusItem(withLength: 26)
        self.statusItem.isVisible = true

        super.init()

        configureButton()
        observeAppearance()
        reloadTitle()
        NSLog("[Cuprim] status item created (click opens dashboard)")
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
        button.target = self
        button.action = #selector(toggleDashboard)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.menu = nil
    }

    private func observeAppearance() {
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

    // MARK: - Actions

    @objc private func toggleDashboard() {
        guard let button = statusItem.button else { return }
        panel.toggle(relativeTo: button)
    }

    func showDashboardFromNotification() {
        openDashboard(tab: .overview)
    }

    private func openDashboard(tab: ProviderTab) {
        guard let button = statusItem.button else { return }
        uiState.selectedTab = tab
        panel.show(relativeTo: button)
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

        let remaining = usage.worstRemainingPercent
        let severity = MenuBarTooltip.severity(
            worstUsedFraction: usage.worstUsedFraction,
            hasVisibleError: usage.visibleSnapshots.contains { $0.status.failureKind != nil },
            hasVisibleOK: usage.visibleSnapshots.contains { if case .ok = $0.status { return true }; return false },
            isRefreshing: kind == .refreshing
        )
        button.toolTip = MenuBarTooltip.text(remainingPercent: remaining, severity: severity)
    }

    private func syncRefreshAnimation(isRefreshing: Bool) {
        if isRefreshing {
            guard refreshTimer == nil else { return }
            refreshPhase = 0
            let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
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
