import Foundation

/// Bounded reset-window ledger for low-quota alerts. One blob instead of
/// unbounded UserDefaults keys.
public struct LowQuotaAlertLedger: Codable, Equatable, Sendable {
    public struct Window: Codable, Equatable, Sendable {
        public var sent: [Int]
        public var expiresAt: Date?
        /// When this window was last recorded. Used to age out windows that
        /// never got a real `expiresAt` (e.g. a reset-less metric), so a
        /// muted alert doesn't stay muted forever.
        public var lastUpdatedAt: Date

        public init(sent: [Int] = [], expiresAt: Date? = nil, lastUpdatedAt: Date = .now) {
            self.sent = sent
            self.expiresAt = expiresAt
            self.lastUpdatedAt = lastUpdatedAt
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sent = try container.decode([Int].self, forKey: .sent)
            expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
            lastUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .lastUpdatedAt) ?? .now
        }
    }

    /// Windows with no real `expiresAt` are aged out after this long, so a
    /// low-quota alert doesn't stay muted across every future quota reset.
    public static let noExpiryTTL: TimeInterval = 14 * 24 * 60 * 60

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

    public mutating func record(key: String, threshold: Int, expiresAt: Date?, now: Date = .now) {
        var window = windows[key] ?? Window(expiresAt: expiresAt, lastUpdatedAt: now)
        if !window.sent.contains(threshold) {
            window.sent.append(threshold)
        }
        window.expiresAt = expiresAt ?? window.expiresAt
        window.lastUpdatedAt = now
        windows[key] = window
    }

    public mutating func prune(now: Date = .now, maxWindows: Int = 40) {
        windows = windows.filter { _, window in
            if let expiresAt = window.expiresAt { return expiresAt > now }
            return now.timeIntervalSince(window.lastUpdatedAt) < Self.noExpiryTTL
        }
        if windows.count <= maxWindows { return }
        // Most-recently-relevant first: a real future expiry beats a
        // reset-less window aged by `lastUpdatedAt`, so nil-expiry entries
        // aren't unconditionally evicted first.
        let sorted = windows.sorted { lhs, rhs in
            let lhsRank = lhs.value.expiresAt ?? lhs.value.lastUpdatedAt
            let rhsRank = rhs.value.expiresAt ?? rhs.value.lastUpdatedAt
            return lhsRank > rhsRank
        }
        windows = Dictionary(uniqueKeysWithValues: sorted.prefix(maxWindows).map { ($0.key, $0.value) })
    }
}
