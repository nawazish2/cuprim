import XCTest
import Foundation
import CuprimCore
import CuprimProviders

final class SnapshotCacheTests: XCTestCase {
    func testPersistsOnlyLastGoodAndRestrictivePermissions() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cuprim-cache-\(UUID().uuidString)", isDirectory: true)
        let cache = SnapshotCache(directory: directory)
        let good = ProviderSnapshot(
            id: .claude,
            planName: "Pro",
            metrics: [Metric(id: "weekly", label: "Weekly", usedFraction: 0.2)],
            status: .ok,
            fetchedAt: Date(timeIntervalSince1970: 50)
        )
        let failed = ProviderSnapshot.failed(.codex, .offline, at: Date(timeIntervalSince1970: 51))
        try cache.save([.claude: good, .codex: failed])

        let loaded = cache.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[.claude]?.status, .ok)
        XCTAssertNil(loaded[.codex])

        let data = try Data(contentsOf: cache.fileURL)
        let text = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("Offline"))
        XCTAssertFalse(text.lowercased().contains("bearer"))

        let fileMode = try FileManager.default.attributesOfItem(atPath: cache.fileURL.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(fileMode?.intValue, 0o600)
        let dirMode = try FileManager.default.attributesOfItem(atPath: directory.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(dirMode?.intValue, 0o700)
    }

    func testLoadSkipsUnknownProviderKeys() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("cuprim-cache-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let cache = SnapshotCache(directory: directory)
        let good = ProviderSnapshot(
            id: .claude,
            planName: "Pro",
            metrics: [Metric(id: "weekly", label: "Weekly", usedFraction: 0.2)],
            status: .ok,
            fetchedAt: Date(timeIntervalSince1970: 50)
        )
        try cache.save([.claude: good])
        let existing = String(decoding: try Data(contentsOf: cache.fileURL), as: UTF8.self)
        guard existing.hasPrefix("["), existing.hasSuffix("]") else {
            XCTFail("expected unkeyed JSON, got \(existing)")
            return
        }
        var json = String(existing.dropLast())
        json += #","antigravity",{"id":"antigravity","planName":"Pro","metrics":[],"status":{"ok":{}},"fetchedAt":50}]"#
        try Data(json.utf8).write(to: cache.fileURL)

        let loaded = cache.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[.claude]?.planName, "Pro")
    }

    func testRefreshGateCoalescesConcurrentWork() async {
        let gate = RefreshGate()
        let counter = Counter()
        async let first: Void = gate.run {
            try? await Task.sleep(for: .milliseconds(80))
            await counter.increment()
        }
        async let second: Void = gate.run {
            await counter.increment()
        }
        _ = await (first, second)
        let value = await counter.value
        XCTAssertEqual(value, 1)
    }

    func testTimeoutThrowsTimedOut() async {
        do {
            _ = try await AsyncTimeout.run(seconds: 0.05) {
                try await Task.sleep(for: .seconds(2))
                return 1
            }
            XCTFail("expected timeout")
        } catch {
            XCTAssertEqual(ProviderStatusMapping.kind(for: error), .timedOut)
        }
    }
}

private actor Counter {
    var value = 0
    func increment() { value += 1 }
}
