import Foundation
import CuprimCore

/// Persists only last-good quota snapshots. Never stores response bodies or errors.
public struct SnapshotCache: Sendable {
    private let directory: URL
    private let fileName = "snapshots.json"

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

    public func load() -> [ProviderID: ProviderSnapshot] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        let decoded = (try? JSONDecoder().decode([ProviderID: ProviderSnapshot].self, from: data)) ?? [:]
        return decoded.filter { _, snapshot in
            if case .ok = snapshot.status { return true }
            return false
        }
    }

    public func save(_ snapshots: [ProviderID: ProviderSnapshot]) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        try fm.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directory.path
        )
        let lastGood = snapshots.filter { _, snapshot in
            if case .ok = snapshot.status { return true }
            return false
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(lastGood)

        let temp = directory.appendingPathComponent("snapshots.json.tmp")
        try data.write(to: temp, options: .atomic)
        if fm.fileExists(atPath: fileURL.path) {
            _ = try fm.replaceItemAt(fileURL, withItemAt: temp)
        } else {
            try fm.moveItem(at: temp, to: fileURL)
        }
        try fm.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    public func deleteLegacyHistory(named fileName: String = "quota-history.json") {
        let fm = FileManager.default
        let candidates = [
            directory.appendingPathComponent(fileName),
            directory.deletingLastPathComponent().appendingPathComponent(fileName)
        ]
        for url in candidates where fm.fileExists(atPath: url.path) {
            try? fm.removeItem(at: url)
        }
    }
}
