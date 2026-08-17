import AppKit
import Foundation
import UserNotifications
import CuprimCore

/// Delivers opt-in local threshold alerts and deduplicates them per reset
/// window. No provider data is sent anywhere other than the provider API.
@MainActor
final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var authorizationRequested = false
    var onOpen: (() -> Void)?

    override init() {
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
    }

    func requestAuthorizationIfNeeded() {
        guard !authorizationRequested else { return }
        authorizationRequested = true
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }
    }

    func scheduleIfNeeded(
        provider: ProviderID,
        metric: Metric,
        snapshot: ProviderSnapshot,
        thresholds: [Int]
    ) {
        guard case .ok = snapshot.status,
              let used = metric.usedFraction
        else { return }

        let remaining = Utilization.remainingPercent(usedFraction: used)
        let resetKey = metric.resetsAt.map { String(Int($0.timeIntervalSince1970)) } ?? "none"
        for threshold in thresholds where remaining <= threshold {
            let key = "alerts.sent.\(provider.rawValue).\(metric.id).\(resetKey).\(threshold)"
            guard !UserDefaults.standard.bool(forKey: key) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(provider.displayName) · \(remaining)% left on \(metric.displayLabel)"
            let reset = QuotaFormatting.resetLabel(for: metric.resetsAt, absolute: false)
            content.body = reset.isEmpty ? "Local quota alert" : reset
            content.sound = .default
            content.categoryIdentifier = "CUPrim.Quota"

            let request = UNNotificationRequest(
                identifier: key,
                content: content,
                trigger: nil
            )
            center.add(request) { error in
                if let error {
                    NSLog("[Cuprim] notification failed: %@", error.localizedDescription)
                } else {
                    UserDefaults.standard.set(true, forKey: key)
                }
            }
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
