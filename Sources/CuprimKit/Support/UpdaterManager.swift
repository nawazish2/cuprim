import AppKit
import Combine
import Foundation
import Sparkle

@MainActor
final class UpdaterManager: NSObject, ObservableObject, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    static let shared = UpdaterManager()

    private var controller: SPUStandardUpdaterController!
    private var activationEntered = false

    @Published var canCheckForUpdates = false

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set { controller.updater.automaticallyChecksForUpdates = newValue }
    }

    private override init() {
        super.init()
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: self,
            userDriverDelegate: self
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func start() {
        #if DEBUG
        return
        #else
        controller.startUpdater()
        #endif
    }

    func checkForUpdates() {
        #if DEBUG
        presentDebugMessage()
        #else
        AppActivationPolicy.enter()
        activationEntered = true
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
        #endif
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        leaveActivationIfNeeded()
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: Error) {
        leaveActivationIfNeeded()
    }

    private func leaveActivationIfNeeded() {
        guard activationEntered else { return }
        activationEntered = false
        AppActivationPolicy.leave()
    }

    private func presentDebugMessage() {
        let alert = NSAlert()
        alert.messageText = "You’re on a debug build"
        alert.informativeText = "Update checks run in release builds of Cuprim."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
