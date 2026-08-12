import AppKit
import Foundation
import CuprimCore

@MainActor
final class AppContainer {
    let preferences = PreferencesStore()
    let uiState = DashboardUIState()
    let usage: UsageStore
    private let notifications: NotificationCoordinator
    private var statusItem: StatusItemController?
    private var panel: PanelController?

    init() {
        notifications = NotificationCoordinator()
        usage = UsageStore(notifications: notifications, preferences: preferences)
    }

    func start() {
        // Cuprim is a menu-bar utility. A Dock icon appears only while a real
        // Settings/About window is open.
        NSApp.setActivationPolicy(.accessory)
        SettingsOpener.configure(preferences: preferences, usage: usage)

        let panel = PanelController(
            usage: usage,
            preferences: preferences,
            uiState: uiState,
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

        // Dev-only: prove Settings presentation path without status-menu tracking.
        if ProcessInfo.processInfo.environment["CUPRIM_OPEN_SETTINGS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                SettingsOpener.open()
            }
        }

        NSLog("[Cuprim] menu bar status item started")
    }
}
