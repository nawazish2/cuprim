import Foundation

/// Bounded reset-window ledger for low-quota alerts. One blob instead of
/// unbounded UserDefaults keys.
public struct LowQuotaAlertLedger: Codable, Equatable, Sendable {
    public struct Window: Codable, Equatable, Sendable {
        public var sent: [Int]
        public var expiresAt: Date?

        public init(sent: [Int] = [], expiresAt: Date? = nil) {
            self.sent = sent
            self.expiresAt = expiresAt
        }
    }

    public var windows: [String: Window]

    public init(windows: [String: Window] = [:]) {
        self.windows = windows
    }

    public static func key(provider: ProviderID, metricID: String, resetKey: String) -> String {
        "\(provider.rawValue).\(metricID).\(resetKey)"
    }

    public func sentThresholds(for key: String) -> Set<Int> {
        Set(windows[key]?.sent ?? [])
    }

    public mutating func record(key: String, threshold: Int, expiresAt: Date?) {
        var window = windows[key] ?? Window(expiresAt: expiresAt)
        if !window.sent.contains(threshold) {
            window.sent.append(threshold)
        }
        window.expiresAt = expiresAt ?? window.expiresAt
        windows[key] = window
    }

    public mutating func prune(now: Date = .now, maxWindows: Int = 40) {
        windows = windows.filter { _, window in
            guard let expiresAt = window.expiresAt else { return true }
            return expiresAt > now
        }
        if windows.count <= maxWindows { return }
        let sorted = windows.sorted { lhs, rhs in
            (lhs.value.expiresAt ?? .distantPast) > (rhs.value.expiresAt ?? .distantPast)
        }
        windows = Dictionary(uniqueKeysWithValues: sorted.prefix(maxWindows).map { ($0.key, $0.value) })
    }
}
