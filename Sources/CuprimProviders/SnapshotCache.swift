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
        let decoded = (try? JSONDecoder().decode(KnownProviderSnapshots.self, from: data))?.snapshots ?? [:]
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

/// Decodes a provider-keyed snapshot map while ignoring unknown provider ids.
/// `JSONEncoder` writes `[ProviderID: ProviderSnapshot]` as an unkeyed key/value list.
private struct KnownProviderSnapshots: Decodable {
    var snapshots: [ProviderID: ProviderSnapshot]

    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    private struct JSONSkip: Decodable {
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() { return }
            if (try? container.decode(Bool.self)) != nil { return }
            if (try? container.decode(Double.self)) != nil { return }
            if (try? container.decode(String.self)) != nil { return }
            if (try? container.decode([JSONSkip].self)) != nil { return }
            if (try? container.decode([String: JSONSkip].self)) != nil { return }
        }
    }

    init(from decoder: Decoder) throws {
        var snapshots: [ProviderID: ProviderSnapshot] = [:]
        if var list = try? decoder.unkeyedContainer() {
            while !list.isAtEnd {
                let key = try list.decode(String.self)
                if let id = ProviderID(rawValue: key) {
                    snapshots[id] = try list.decode(ProviderSnapshot.self)
                } else {
                    _ = try list.decode(JSONSkip.self)
                }
            }
        } else {
            let object = try decoder.container(keyedBy: Key.self)
            for key in object.allKeys {
                guard let id = ProviderID(rawValue: key.stringValue) else { continue }
                guard let snapshot = try? object.decode(ProviderSnapshot.self, forKey: key) else { continue }
                snapshots[id] = snapshot
            }
        }
        self.snapshots = snapshots
    }
}
