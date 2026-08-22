import XCTest
import Foundation
import CuprimCore
import CuprimProviders

final class UsageHistoryTests: XCTestCase {
    /// A multiple of both bucket sizes used below, so bucket edges are exact.
    private let base = Date(timeIntervalSince1970: 1_000_800)

    private func series(bucketSeconds: Int = 300) -> MetricSeries {
        MetricSeries(provider: .claude, metricID: "session", bucketSeconds: bucketSeconds)
    }

    // MARK: - Encoding

    func testUnknownRoundTripsAsUnknownNotZero() {
        XCTAssertEqual(MetricSeries.encode(nil), MetricSeries.noSample)
        XCTAssertNil(MetricSeries.decode(MetricSeries.noSample))
        // The distinction that matters: a real zero is not the same as a gap.
        XCTAssertEqual(MetricSeries.encode(0), 0)
        XCTAssertEqual(MetricSeries.decode(0), 0)
    }

    func testFractionRoundTripsWithinBasisPointPrecision() {
        let value = MetricSeries.encode(0.4237)
        XCTAssertEqual(MetricSeries.decode(value) ?? -1, 0.4237, accuracy: 1e-4)
    }

    // MARK: - Recording

    func testGapsBetweenRefreshesStayUnknown() {
        var s = series()
        s.record(usedFraction: 0.10, resetsAt: nil, at: base)
        // Three buckets later, so two buckets were never sampled.
        s.record(usedFraction: 0.40, resetsAt: nil, at: base.addingTimeInterval(900))

        XCTAssertEqual(s.values.count, 4)
        XCTAssertNil(MetricSeries.decode(s.values[1]))
        XCTAssertNil(MetricSeries.decode(s.values[2]))
        XCTAssertEqual(MetricSeries.decode(s.values[3]) ?? -1, 0.40, accuracy: 1e-4)
    }

    func testLastWriteWinsWithinABucket() {
        var s = series()
        s.record(usedFraction: 0.10, resetsAt: nil, at: base)
        s.record(usedFraction: 0.20, resetsAt: nil, at: base.addingTimeInterval(100))

        XCTAssertEqual(s.values.count, 1)
        XCTAssertEqual(MetricSeries.decode(s.values[0]) ?? -1, 0.20, accuracy: 1e-4)
    }

    func testSamplesOlderThanTheSeriesAreDropped() {
        var s = series()
        s.record(usedFraction: 0.10, resetsAt: nil, at: base)
        s.record(usedFraction: 0.99, resetsAt: nil, at: base.addingTimeInterval(-3_600))

        XCTAssertEqual(s.values.count, 1)
        XCTAssertEqual(MetricSeries.decode(s.values[0]) ?? -1, 0.10, accuracy: 1e-4)
    }

    // MARK: - Window runs

    func testWindowRunsRecordOnlyWhenTheResetChanges() {
        let first = base.addingTimeInterval(5 * 3_600)
        let second = base.addingTimeInterval(10 * 3_600)
        var s = series()
        s.record(usedFraction: 0.10, resetsAt: first, at: base)
        s.record(usedFraction: 0.20, resetsAt: first, at: base.addingTimeInterval(300))
        s.record(usedFraction: 0.05, resetsAt: second, at: base.addingTimeInterval(600))

        XCTAssertEqual(s.windows, [
            WindowRun(startIndex: 0, resetsAt: first),
            WindowRun(startIndex: 2, resetsAt: second)
        ])
    }

    /// The point of the run encoding: a projection must see only the newest
    /// window, never the sawtooth across a reset.
    func testCurrentWindowExcludesEarlierWindows() {
        let first = base.addingTimeInterval(5 * 3_600)
        let second = base.addingTimeInterval(10 * 3_600)
        var s = series()
        s.record(usedFraction: 0.80, resetsAt: first, at: base)
        s.record(usedFraction: 0.90, resetsAt: first, at: base.addingTimeInterval(300))
        s.record(usedFraction: 0.05, resetsAt: second, at: base.addingTimeInterval(600))
        s.record(usedFraction: 0.10, resetsAt: second, at: base.addingTimeInterval(900))

        let window = s.currentWindow()
        XCTAssertEqual(window.resetsAt, second)
        XCTAssertEqual(window.samples.count, 2)
        XCTAssertEqual(window.samples.first?.usedFraction ?? -1, 0.05, accuracy: 1e-4)
    }

    // MARK: - Trimming

    func testTrimDropsOldBucketsAndKeepsTheActiveWindowsReset() {
        let first = base.addingTimeInterval(90 * 60)
        let second = base.addingTimeInterval(10 * 3_600)
        var s = series(bucketSeconds: 3_600)
        s.record(usedFraction: 0.10, resetsAt: first, at: base)
        s.record(usedFraction: 0.20, resetsAt: first, at: base.addingTimeInterval(3_600))
        s.record(usedFraction: 0.05, resetsAt: second, at: base.addingTimeInterval(2 * 3_600))
        s.record(usedFraction: 0.15, resetsAt: second, at: base.addingTimeInterval(3 * 3_600))

        s.trim(retaining: 5_400, now: base.addingTimeInterval(3 * 3_600))

        XCTAssertEqual(s.values.count, 3)
        // The run covering the retained region survives, clamped to index 0.
        XCTAssertEqual(s.windows, [
            WindowRun(startIndex: 0, resetsAt: first),
            WindowRun(startIndex: 1, resetsAt: second)
        ])
        XCTAssertEqual(s.currentWindow().resetsAt, second)
    }

    func testTrimIsANoOpWhenEverythingIsRecent() {
        var s = series(bucketSeconds: 3_600)
        s.record(usedFraction: 0.10, resetsAt: nil, at: base)
        s.record(usedFraction: 0.20, resetsAt: nil, at: base.addingTimeInterval(3_600))
        let before = s

        s.trim(retaining: 7 * 24 * 3_600, now: base.addingTimeInterval(3_600))
        XCTAssertEqual(s, before)
    }

    // MARK: - History container

    func testOnlyOKSnapshotsAreRecorded() {
        var history = UsageHistory()
        history.record(snapshot: .failed(.claude, .offline, at: base), at: base)
        XCTAssertTrue(history.series.isEmpty)

        history.record(
            snapshot: ProviderSnapshot(
                id: .claude,
                metrics: [Metric(id: "session", label: "5-hour", usedFraction: 0.3)],
                status: .ok,
                fetchedAt: base
            ),
            at: base
        )
        XCTAssertEqual(history.series.count, 1)
        XCTAssertEqual(history.series(provider: .claude, metricID: "session")?.values.count, 1)
    }
}

final class UsageHistoryStoreTests: XCTestCase {
    private func directory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("cuprim-history-\(UUID().uuidString)", isDirectory: true)
    }

    func testRoundTripsAndUsesRestrictivePermissions() async throws {
        let dir = directory()
        let store = UsageHistoryStore(directory: dir)
        let now = Date(timeIntervalSince1970: 1_000_800)

        var history = UsageHistory()
        history.record(
            snapshot: ProviderSnapshot(
                id: .codex,
                metrics: [Metric(id: "primary", label: "Primary", usedFraction: 0.25)],
                status: .ok,
                fetchedAt: now
            ),
            at: now
        )
        try await store.save(history, now: now)

        let loaded = await store.load(now: now)
        XCTAssertEqual(loaded.version, UsageHistory.currentVersion)
        XCTAssertEqual(loaded.series(provider: .codex, metricID: "primary")?.values.count, 1)

        let url = await store.fileURL
        let fileMode = try FileManager.default
            .attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(fileMode?.intValue, 0o600)
        let dirMode = try FileManager.default
            .attributesOfItem(atPath: dir.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(dirMode?.intValue, 0o700)
    }

    func testCorruptFileLoadsAsEmptyAndIsNotDeleted() async throws {
        let dir = directory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let store = UsageHistoryStore(directory: dir)
        let url = await store.fileURL
        try Data(#"{"version":1,"series":[{"provider":"#.utf8).write(to: url)

        let loaded = await store.load()
        XCTAssertTrue(loaded.series.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testUnknownVersionLoadsAsEmpty() async throws {
        let dir = directory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let store = UsageHistoryStore(directory: dir)
        let url = await store.fileURL
        try Data(#"{"version":99,"series":[]}"#.utf8).write(to: url)

        let loaded = await store.load()
        XCTAssertTrue(loaded.series.isEmpty)
    }
}
