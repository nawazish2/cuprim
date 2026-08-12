import Foundation
import CuprimCore

/// Small JSON history store. It is deliberately independent from the provider
/// credentials and is pruned aggressively so Quota Horizon stays local/light.
struct QuotaHistoryStore: Sendable {
    private let fileURL: URL
    private let retention: TimeInterval = 14 * 86_400

    init(directory: URL? = nil) {
        let base = directory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let root = base.appendingPathComponent("Cuprim", isDirectory: true)
        self.fileURL = root.appendingPathComponent("quota-history.json")
    }

    func load() -> [String: [UsageSample]] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: [UsageSample]].self, from: data)
        else { return [:] }
        return decoded
    }

    @discardableResult
    func append(provider: ProviderID, metric: Metric, at date: Date = .now) -> [UsageSample] {
        guard let used = metric.usedFraction else { return [] }
        var history = load()
        let key = "\(provider.rawValue).\(metric.id)"
        let cutoff = date.addingTimeInterval(-retention)
        var samples = (history[key] ?? []).filter { $0.timestamp >= cutoff }
        samples.append(UsageSample(timestamp: date, usedFraction: used, resetsAt: metric.resetsAt))
        samples.sort { $0.timestamp < $1.timestamp }
        history[key] = samples
        save(history)
        return samples
    }

    func samples(provider: ProviderID, metricID: String) -> [UsageSample] {
        load()["\(provider.rawValue).\(metricID)"] ?? []
    }

    private func save(_ history: [String: [UsageSample]]) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(history)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("[Cuprim] quota history write failed: %@", error.localizedDescription)
        }
    }
}
