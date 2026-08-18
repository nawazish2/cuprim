import AppKit
import Foundation
import UserNotifications
import CuprimCore

/// Delivers opt-in local threshold alerts and deduplicates them per reset window.
@MainActor
final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var authorizationRequested = false
    private let defaults: UserDefaults
    private let ledgerKey = "alerts.lowQuota.ledger"
    var onOpen: (() -> Void)?

    enum Permission: Equatable {
        case notDetermined
        case authorized
        case denied
        case unknown
    }

    private(set) var permission: Permission = .unknown

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        center.delegate = self
        let open = UNNotificationAction(
            identifier: "CUPrim.OpenDashboard",
            title: "Open Cuprim",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "CUPrim.Quota",
            actions: [open],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
        Task { await refreshPermission() }
    }

    func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        authorizationRequested = true
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            await refreshPermission()
        }
    }

    func refreshPermission() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: permission = .notDetermined
        case .authorized, .provisional, .ephemeral: permission = .authorized
        case .denied: permission = .denied
        @unknown default: permission = .unknown
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func scheduleIfNeeded(snapshot: ProviderSnapshot) {
        guard case .ok = snapshot.status else { return }
        var ledger = loadLedger()
        ledger.prune()

        for metric in snapshot.metrics {
            guard let used = metric.usedFraction else { continue }
            let remaining = LowQuotaAlertPolicy.remainingPercent(usedFraction: used)
            let resetKey = metric.resetsAt.map { String(Int($0.timeIntervalSince1970)) } ?? "none"
            let key = LowQuotaAlertLedger.key(provider: snapshot.id, metricID: metric.id, resetKey: resetKey)
            let already = ledger.sentThresholds(for: key)
            guard let threshold = LowQuotaAlertPolicy.newlyReachedThreshold(
                remainingPercent: remaining,
                alreadySent: already
            ) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(snapshot.id.displayName) · \(remaining)% left on \(metric.displayLabel)"
            let reset = QuotaFormatting.resetLabel(for: metric.resetsAt, absolute: false)
            content.body = reset.isEmpty ? "Local quota alert" : reset
            content.sound = .default
            content.categoryIdentifier = "CUPrim.Quota"

            let request = UNNotificationRequest(
                identifier: key + ".\(threshold)",
                content: content,
                trigger: nil
            )
            center.add(request) { [weak self] error in
                if let error {
                    NSLog("[Cuprim] notification failed: %@", error.localizedDescription)
                    return
                }
                Task { @MainActor in
                    guard let self else { return }
                    var next = self.loadLedger()
                    next.record(key: key, threshold: threshold, expiresAt: metric.resetsAt)
                    next.prune()
                    self.saveLedger(next)
                }
            }
        }
        saveLedger(ledger)
    }

    private func loadLedger() -> LowQuotaAlertLedger {
        guard let data = defaults.data(forKey: ledgerKey),
              let decoded = try? JSONDecoder().decode(LowQuotaAlertLedger.self, from: data)
        else { return LowQuotaAlertLedger() }
        return decoded
    }

    private func saveLedger(_ ledger: LowQuotaAlertLedger) {
        if let data = try? JSONEncoder().encode(ledger) {
            defaults.set(data, forKey: ledgerKey)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "CUPrim.OpenDashboard" ||
            response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in
                NSApp.activate(ignoringOtherApps: true)
                self.onOpen?()
            }
        }
        completionHandler()
    }
}
