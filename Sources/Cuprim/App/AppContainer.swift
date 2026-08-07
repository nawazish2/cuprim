import AppKit
import Foundation
import CuprimCore

@MainActor
final class AppContainer {
    let preferences = PreferencesStore()
    let uiState = DashboardUIState()
    let usage: UsageStore
    private var statusItem: StatusItemController?
    private var panel: PanelController?
    private var titleTimer: Timer?

    init() {
        usage = UsageStore(preferences: preferences)
    }

    func start() {
        // Regular policy → Dock icon (AppIcon) is visible. Menu bar item still works.
        NSApp.setActivationPolicy(.regular)

        let panel = PanelController(
            usage: usage,
            preferences: preferences,
            uiState: uiState,
            onOpenSettings: {
                SettingsOpener.open()
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

        usage.start()

        titleTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.statusItem?.reloadTitle()
            }
        }
        if let titleTimer {
            RunLoop.main.add(titleTimer, forMode: .common)
        }

        NSLog("[Cuprim] menu bar status item started")
    }
}
