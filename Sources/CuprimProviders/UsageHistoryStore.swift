import Foundation
import CuprimCore

/// Persists bounded usage history. Same private-directory discipline as
/// `SnapshotCache`: 0700 directory, 0600 file, atomic temp-then-replace.
///
/// Deliberately not named or shaped like the deleted `quota-history.json`,
/// which stored one JSON object per sample and would have run to megabytes.
/// `SnapshotCache.deleteLegacyHistory()` still removes that old file.
public actor UsageHistoryStore {
    /// A corrupt length field must not be able to allocate an unbounded array.
    /// Two weeks of five-minute buckets is already twice what is retained.
    public static let maxBucketsPerSeries = 2 * 7 * 24 * 12

    private let directory: URL
    private let fileName = "usage-series.v1.json"

    public init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.directory = base.appendingPathComponent("Cuprim", isDirectory: true)
                .appendingPathComponent("Private", isDirectory: true)
        }
    }

    public var fileURL: URL {
        directory.appendingPathComponent(fileName)
    }

    /// Any unreadable state yields an empty history that the next flush
    /// overwrites. Never deletes and retries — a bad read is not a reason to
    /// destroy a file the user might still want to inspect.
    public func load(now: Date = .now) -> UsageHistory {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(UsageHistory.self, from: data),
              decoded.version == UsageHistory.currentVersion
        else {
            return UsageHistory()
        }

        var history = UsageHistory(
            version: decoded.version,
            series: decoded.series.filter { $0.values.count <= Self.maxBucketsPerSeries }
        )
        history.trim(now: now)
        return history
    }

    public func save(_ history: UsageHistory, now: Date = .now) throws {
        var trimmed = history
        trimmed.trim(now: now)

        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(trimmed)

        let temp = directory.appendingPathComponent("\(fileName).tmp")
        try data.write(to: temp, options: .atomic)
        if fm.fileExists(atPath: fileURL.path) {
            _ = try fm.replaceItemAt(fileURL, withItemAt: temp)
        } else {
            try fm.moveItem(at: temp, to: fileURL)
        }
        try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
}
