import AppKit
import Foundation
import TokenBarCore

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
            onOpenSettings: { [weak self] in
                guard let self else { return }
                SettingsWindowController.show(preferences: self.preferences)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        self.panel = panel

        statusItem = StatusItemController(
            usage: usage,
            preferences: preferences,
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

        NSLog("[TokenBar] menu bar status item started")
    }
}
