import XCTest
import Foundation
import CuprimCore
import CuprimProviders
@testable import CuprimKit

// MARK: - Test doubles

/// Plays back a scripted sequence of results, repeating the last one once the
/// script runs out, and records how many times it was actually asked to refresh.
private final class ScriptedProvider: ProviderRuntime, @unchecked Sendable {
    let id: ProviderID
    private let lock = NSLock()
    private var remaining: [Result<ProviderSnapshot, Error>]
    private var calls = 0

    init(_ id: ProviderID, _ results: [Result<ProviderSnapshot, Error>]) {
        self.id = id
        self.remaining = results
    }

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return calls
    }

    func refresh() async throws -> ProviderSnapshot {
        lock.lock()
        calls += 1
        let result: Result<ProviderSnapshot, Error>
        if remaining.count > 1 {
            result = remaining.removeFirst()
        } else {
            result = remaining.first ?? .failure(ProviderError.unavailable)
        }
        lock.unlock()
        return try result.get()
    }
}

@MainActor
private final class RecordingAlerter: QuotaAlerting {
    private(set) var scheduled: [ProviderSnapshot] = []

    func requestAuthorizationIfNeeded() {}

    func scheduleIfNeeded(snapshot: ProviderSnapshot) {
        scheduled.append(snapshot)
    }
}

@MainActor
private struct StubLaunchAtLogin: LaunchAtLoginControlling {
    var state: LaunchAtLoginState { .unavailable }
    func setEnabled(_ enabled: Bool) throws {}
}

// MARK: - Tests

@MainActor
final class UsageStoreTests: XCTestCase {
    private func makeCache() -> SnapshotCache {
        SnapshotCache(
            directory: FileManager.default.temporaryDirectory
                .appendingPathComponent("cuprim-store-\(UUID().uuidString)", isDirectory: true)
        )
    }

    /// A per-test defaults suite so these never touch the runner's own domain
    /// and never leak state between runs.
    private func makePreferences(only enabled: ProviderID...) -> PreferencesStore {
        let suite = "cuprim.tests.\(UUID().uuidString)"
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: suite) }
        let defaults = UserDefaults(suiteName: suite)!
        let preferences = PreferencesStore(defaults: defaults, launchAtLogin: StubLaunchAtLogin())
        if !enabled.isEmpty {
            for id in ProviderID.allCases {
                preferences.setEnabled(id, enabled.contains(id))
            }
        }
        return preferences
    }

    private func okSnapshot(_ id: ProviderID, used: Double) -> ProviderSnapshot {
        ProviderSnapshot(
            id: id,
            planName: "Pro",
            metrics: [Metric(id: "session", label: "5-hour limit", usedFraction: used)],
            status: .ok,
            fetchedAt: Date(timeIntervalSince1970: 1_000)
        )
    }

    private func makeStore(
        _ providers: [any ProviderRuntime],
        _ preferences: PreferencesStore,
        _ alerter: RecordingAlerter
    ) -> UsageStore {
        UsageStore(
            providers: providers,
            cache: makeCache(),
            notifications: alerter,
            preferences: preferences
        )
    }

    /// A merged last-good snapshot still reads `.ok`, so alerting on status
    /// alone would re-fire the same alert on every refresh while a provider is
    /// unreachable. Only a genuinely fresh reading may alert.
    func testAlertsOnlyForFreshlyOKProviders() async {
        let preferences = makePreferences(only: .claude)
        preferences.lowQuotaAlertsEnabled = true
        let alerter = RecordingAlerter()
        let provider = ScriptedProvider(.claude, [
            .success(okSnapshot(.claude, used: 0.9)),
            .failure(URLError(.notConnectedToInternet))
        ])
        let store = makeStore([provider], preferences, alerter)

        await store.refresh()
        XCTAssertEqual(alerter.scheduled.count, 1)

        await store.refresh()
        XCTAssertEqual(alerter.scheduled.count, 1)
        XCTAssertEqual(store.snapshots[.claude]?.status, .ok)
    }

    func testTransientFailureKeepsLastGoodMeters() async {
        let preferences = makePreferences(only: .claude)
        let provider = ScriptedProvider(.claude, [
            .success(okSnapshot(.claude, used: 0.42)),
            .failure(URLError(.notConnectedToInternet))
        ])
        let store = makeStore([provider], preferences, RecordingAlerter())

        await store.refresh()
        XCTAssertEqual(store.snapshots[.claude]?.metrics.first?.usedFraction, 0.42)

        await store.refresh()
        XCTAssertEqual(store.snapshots[.claude]?.metrics.first?.usedFraction, 0.42)
        XCTAssertEqual(store.snapshots[.claude]?.status, .ok)
        XCTAssertEqual(store.lastFailures[.claude], .offline)
    }

    func testDurableFailureReplacesLastGoodMeters() async {
        let preferences = makePreferences(only: .claude)
        let provider = ScriptedProvider(.claude, [
            .success(okSnapshot(.claude, used: 0.42)),
            .failure(ProviderError.signedOut)
        ])
        let store = makeStore([provider], preferences, RecordingAlerter())

        await store.refresh()
        XCTAssertEqual(store.snapshots[.claude]?.metrics.count, 1)

        await store.refresh()
        XCTAssertEqual(store.snapshots[.claude]?.status, .failed(.signedOut))
        XCTAssertEqual(store.snapshots[.claude]?.metrics.count, 0)
        XCTAssertEqual(store.lastFailures[.claude], .signedOut)
    }

    func testOfflineFlagTracksTheLatestRefresh() async {
        let preferences = makePreferences(only: .claude)
        let provider = ScriptedProvider(.claude, [
            .failure(URLError(.notConnectedToInternet)),
            .success(okSnapshot(.claude, used: 0.1))
        ])
        let store = makeStore([provider], preferences, RecordingAlerter())

        await store.refresh()
        XCTAssertTrue(store.isOffline)

        // Recovering must clear the flag, not latch it.
        await store.refresh()
        XCTAssertFalse(store.isOffline)
    }

    func testDisabledProvidersAreNotFetched() async {
        let preferences = makePreferences(only: .claude)
        let claude = ScriptedProvider(.claude, [.success(okSnapshot(.claude, used: 0.1))])
        let codex = ScriptedProvider(.codex, [.success(okSnapshot(.codex, used: 0.1))])
        let store = makeStore([claude, codex], preferences, RecordingAlerter())

        await store.refresh()

        XCTAssertEqual(claude.callCount, 1)
        XCTAssertEqual(codex.callCount, 0)
        XCTAssertNil(store.snapshots[.codex])
    }
}
