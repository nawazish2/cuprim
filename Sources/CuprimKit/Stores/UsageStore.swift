import Foundation
import Observation
import CuprimCore
import CuprimProviders

@MainActor
@Observable
final class UsageStore {
    private(set) var snapshots: [ProviderID: ProviderSnapshot] = [:]
    private(set) var lastFailures: [ProviderID: ProviderFailureKind] = [:]
    private(set) var lastSuccessAt: [ProviderID: Date] = [:]
    private(set) var lastSuccessfulRefresh: Date?
    private(set) var isRefreshing = false
    private(set) var isOffline = false

    private let providers: [any ProviderRuntime]
    private let cache: SnapshotCache
    private let notifications: any QuotaAlerting
    private let preferences: PreferencesStore
    private let gate = RefreshGate()
    private var loopTask: Task<Void, Never>?
    private let providerTimeout: TimeInterval = 15

    private let history: UsageHistoryStore
    /// In-memory mirror of the history file. Observed, so a view reading a burn
    /// projection re-renders when new samples land.
    private var historyCache = UsageHistory()
    @ObservationIgnored private var pendingHistoryAppends = 0
    @ObservationIgnored private var lastHistoryFlush = Date.distantPast
    @ObservationIgnored private let historyFlushInterval: TimeInterval = 300
    @ObservationIgnored private let historyFlushAppendCount = 20

    var onStateChange: (() -> Void)?

    init(
        providers: [any ProviderRuntime] = [
            ClaudeProvider(),
            CodexProvider(),
            CursorProvider(),
            GrokProvider()
        ],
        cache: SnapshotCache,
        history: UsageHistoryStore,
        notifications: any QuotaAlerting,
        preferences: PreferencesStore
    ) {
        self.providers = providers
        self.cache = cache
        self.history = history
        self.notifications = notifications
        self.preferences = preferences
        cache.deleteLegacyHistory()
        if DemoSnapshots.isEnabled {
            snapshots = DemoSnapshots.all()
            historyCache = DemoSnapshots.history()
            lastSuccessfulRefresh = .now
            for (id, snapshot) in snapshots {
                lastSuccessAt[id] = snapshot.fetchedAt
            }
        } else {
            snapshots = cache.load()
            lastSuccessfulRefresh = snapshots.values.map(\.fetchedAt).max()
            for (id, snapshot) in snapshots {
                if case .ok = snapshot.status {
                    lastSuccessAt[id] = snapshot.fetchedAt
                }
            }
        }
    }

    /// Providers the dashboard should show, in the user's order. One
    /// definition so the card list and `visibleSnapshots` cannot drift apart.
    var visibleProviderIDs: [ProviderID] {
        preferences.orderedProviders.filter { id in
            guard preferences.isEnabled(id) else { return false }
            if preferences.hideLoggedOutProviders, !preferences.showsFirstLaunchSetup {
                if case .signedOut = presentation(for: id) { return false }
            }
            return true
        }
    }

    var visibleSnapshots: [ProviderSnapshot] {
        visibleProviderIDs.compactMap { id in
            presentation(for: id).snapshot ?? snapshots[id]
        }
    }

    var worstUsedFraction: Double? {
        let fractions = visibleSnapshots
            .filter { if case .ok = $0.status { return true }; return false }
            .flatMap(\.metrics)
            .compactMap(\.usedFraction)
        return fractions.max()
    }

    var worstRemainingPercent: Int? {
        guard let used = worstUsedFraction else { return nil }
        return Utilization.remainingPercent(usedFraction: used)
    }

    var isStale: Bool {
        StalePolicy.isStale(lastSuccessfulRefresh, refreshMinutes: preferences.refreshMinutes)
    }

    func presentation(for id: ProviderID) -> ProviderPresentation {
        ProviderPresentation.make(
            id: id,
            lastGood: snapshots[id],
            lastFailure: lastFailures[id],
            isRefreshing: isRefreshing && snapshots[id] == nil && lastFailures[id] == nil,
            refreshMinutes: preferences.refreshMinutes
        )
    }

    private var autoRefreshSeconds: TimeInterval {
        Double(max(1, preferences.refreshMinutes)) * 60
    }

    func start() {
        if preferences.lowQuotaAlertsEnabled {
            notifications.requestAuthorizationIfNeeded()
        }
        loopTask?.cancel()
        loopTask = Task { [weak self] in
            await self?.loadHistory()
            await self?.refresh()
            while !Task.isCancelled {
                let seconds = await MainActor.run { self?.autoRefreshSeconds ?? 120 }
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { break }
                await self?.refresh()
            }
        }
    }

    func stop() {
        loopTask?.cancel()
        loopTask = nil
        flushHistory(force: true)
    }

    private func loadHistory() async {
        guard !DemoSnapshots.isEnabled else { return }
        historyCache = await history.load()
    }

    /// Burn-rate forecast for one metric, over its current window only.
    func burnProjection(for id: ProviderID, metricID: String, now: Date = .now) -> BurnProjection {
        guard let series = historyCache.series(provider: id, metricID: metricID) else {
            return .unknown(.tooFewSamples)
        }
        let window = series.currentWindow()
        return BurnRate.project(samples: window.samples, resetsAt: window.resetsAt, now: now)
    }

    /// Recent readings for one metric, oldest first. Default covers four hours
    /// at the five-minute bucket size.
    func recentSamples(for id: ProviderID, metricID: String, limit: Int = 48) -> [Double?] {
        historyCache.series(provider: id, metricID: metricID)?.recentValues(limit: limit) ?? []
    }

    /// Writing on every refresh would mean a disk write every two minutes for
    /// data nobody reads until the panel opens, so flushes are debounced.
    /// Losing at most one window on a hard quit is an acceptable trade against
    /// a synchronous write at termination.
    private func flushHistory(force: Bool = false) {
        guard !DemoSnapshots.isEnabled, pendingHistoryAppends > 0 else { return }
        let now = Date.now
        let due = force
            || pendingHistoryAppends >= historyFlushAppendCount
            || now.timeIntervalSince(lastHistoryFlush) >= historyFlushInterval
        guard due else { return }

        pendingHistoryAppends = 0
        lastHistoryFlush = now
        let pending = historyCache
        let store = history
        Task.detached {
            do {
                try await store.save(pending)
            } catch {
                NSLog("[Cuprim] history flush failed: %@", error.localizedDescription)
            }
        }
    }

    func refresh() async {
        if DemoSnapshots.isEnabled { return }
        if preferences.lowQuotaAlertsEnabled {
            notifications.requestAuthorizationIfNeeded()
        }
        let store = self
        await gate.run {
            await store.performRefresh()
        }
    }

    private func performRefresh() async {
        isRefreshing = true
        onStateChange?()
        defer {
            isRefreshing = false
            onStateChange?()
        }

        let previous = snapshots
        var next = snapshots
        var nextFailures = lastFailures
        var nextSuccess = lastSuccessAt
        var sawOffline = false
        var freshlyOK = Set<ProviderID>()
        let timeout = providerTimeout
        let enabled = providers.filter { preferences.isEnabled($0.id) }

        await withTaskGroup(of: (ProviderID, Result<ProviderSnapshot, Error>).self) { group in
            for provider in enabled {
                NSLog("[Cuprim] refresh %@", provider.id.rawValue)
                group.addTask {
                    do {
                        let snapshot = try await AsyncTimeout.run(seconds: timeout) {
                            try await provider.refresh()
                        }
                        return (provider.id, .success(snapshot))
                    } catch {
                        return (provider.id, .failure(error))
                    }
                }
            }

            for await (id, result) in group {
                switch result {
                case .success(let snapshot):
                    next[id] = snapshot
                    nextFailures[id] = nil
                    if case .ok = snapshot.status {
                        nextSuccess[id] = snapshot.fetchedAt
                        freshlyOK.insert(id)
                    } else {
                        nextFailures[id] = snapshot.status.failureKind
                    }
                case .failure(let error):
                    if ProviderStatusMapping.isOffline(error) {
                        sawOffline = true
                    }
                    let incoming = ProviderStatusMapping.snapshot(for: id, error: error)
                    next[id] = RefreshMergePolicy.merge(previous: previous[id], incoming: incoming)
                    nextFailures[id] = incoming.status.failureKind
                }
            }
        }

        // Only genuinely fresh readings enter history. Recording a merged
        // last-good snapshot would copy an old value into a new bucket and
        // flatten the slope, understating the real burn rate.
        for id in freshlyOK {
            guard let snapshot = next[id] else { continue }
            historyCache.record(snapshot: snapshot, at: snapshot.fetchedAt)
            pendingHistoryAppends += 1
        }
        flushHistory()

        snapshots = next
        lastFailures = nextFailures
        lastSuccessAt = nextSuccess
        isOffline = sawOffline
        lastSuccessfulRefresh = nextSuccess.values.max()
        try? cache.save(next)

        if preferences.lowQuotaAlertsEnabled {
            for id in freshlyOK {
                guard let snapshot = next[id] else { continue }
                notifications.scheduleIfNeeded(snapshot: snapshot)
            }
        }
        onStateChange?()
    }
}
