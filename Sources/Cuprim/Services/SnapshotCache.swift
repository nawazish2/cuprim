import Foundation
import CuprimCore

struct SnapshotCache: Sendable {
    private let directory: URL
    private let fileName = "snapshots.json"

    init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directory = base.appendingPathComponent("Cuprim", isDirectory: true)
        }
    }

    private var fileURL: URL {
        directory.appendingPathComponent(fileName)
    }

    func load() -> [ProviderID: ProviderSnapshot] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        return (try? JSONDecoder().decode([ProviderID: ProviderSnapshot].self, from: data)) ?? [:]
    }

    func save(_ snapshots: [ProviderID: ProviderSnapshot]) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshots) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
