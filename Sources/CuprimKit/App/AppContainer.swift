import AppKit
import Foundation
import CuprimCore
import CuprimProviders

@MainActor
final class AppContainer {
    let preferences = PreferencesStore()
    let uiState = DashboardUIState()
    let usage: UsageStore
    let notifications: NotificationCoordinator
    private var statusItem: StatusItemController?
    private var panel: PanelController?

    init() {
        notifications = NotificationCoordinator()
        // `cache` is passed explicitly rather than defaulted: `UsageStore.init`
        // calls `deleteLegacyHistory()` on it, so a defaulted cache would let a
        // test delete files under the developer's real Application Support
        // directory just by constructing a store.
        usage = UsageStore(
            cache: SnapshotCache(),
            notifications: notifications,
            preferences: preferences
        )
    }

    func start() {
        // Cuprim is a menu-bar utility. A Dock icon appears only while a real
        // Settings/About window is open.
        NSApp.setActivationPolicy(.accessory)

        let panel = PanelController(
            usage: usage,
            preferences: preferences,
            uiState: uiState,
            onOpenSettings: { [weak self] in
                self?.openSettings()
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        self.panel = panel

        statusItem = StatusItemController(
            usage: usage,
            preferences: preferences,
            uiState: uiState,
            panel: panel
        )

        notifications.onOpen = { [weak self] in
            self?.statusItem?.showDashboardFromNotification()
        }

        usage.onStateChange = { [weak self] in
            self?.statusItem?.reloadTitle()
        }

        usage.start()

        if preferences.showsFirstLaunchSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.statusItem?.showDashboardFromNotification()
            }
        }

        // Dev-only: prove Settings presentation path without status-menu tracking.
        if ProcessInfo.processInfo.environment["CUPRIM_OPEN_SETTINGS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.openSettings()
            }
        }

        NSLog("[Cuprim] menu bar status item started")
    }

    private func openSettings() {
        SettingsOpener.open(
            preferences: preferences,
            usage: usage,
            notifications: notifications
        )
    }
}
