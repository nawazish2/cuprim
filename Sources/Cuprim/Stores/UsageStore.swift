import Foundation
import Observation
import CuprimCore

@MainActor
@Observable
final class UsageStore {
    private(set) var snapshots: [ProviderID: ProviderSnapshot] = [:]
    private(set) var isRefreshing = false
    private(set) var lastRefresh: Date?

    private let providers: [any ProviderRuntime]
    private let cache: SnapshotCache
    private let history: QuotaHistoryStore
    private let notifications: NotificationCoordinator
    private let preferences: PreferencesStore
    private var loopTask: Task<Void, Never>?
    private var refreshGeneration = 0

    /// AppContainer uses this to refresh the status glyph only when data changes.
    var onStateChange: (() -> Void)?

    init(
        providers: [any ProviderRuntime] = [
            ClaudeProvider(),
            CodexProvider(),
            CursorProvider(),
            GrokProvider(),
            AntigravityProvider()
        ],
        cache: SnapshotCache = SnapshotCache(),
        history: QuotaHistoryStore = QuotaHistoryStore(),
        notifications: NotificationCoordinator = NotificationCoordinator(),
        preferences: PreferencesStore
    ) {
        self.providers = providers
        self.cache = cache
        self.history = history
        self.notifications = notifications
        self.preferences = preferences
        self.snapshots = cache.load()
    }

    var visibleSnapshots: [ProviderSnapshot] {
        preferences.orderedProviders.compactMap { id in
            guard preferences.isEnabled(id) else { return nil }
            guard let snapshot = snapshots[id] else { return nil }
            if preferences.hideLoggedOutProviders {
                if case .notLoggedIn = snapshot.status { return nil }
            }
            return snapshot
        }
    }

    var hasAnyData: Bool {
        !visibleSnapshots.isEmpty
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
        QuotaFormatting.isStale(lastRefresh, thresholdMinutes: 6)
    }

    func isSnapshotStale(_ snapshot: ProviderSnapshot) -> Bool {
        QuotaFormatting.isStale(snapshot.fetchedAt, thresholdMinutes: 6)
    }

    private var autoRefreshSeconds: TimeInterval {
        Double(max(1, preferences.refreshMinutes)) * 60
    }

    func start() {
        if preferences.horizonAlertsEnabled {
            notifications.requestAuthorizationIfNeeded()
        }
        loopTask?.cancel()
        loopTask = Task { [weak self] in
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
    }

    /// Manual or automatic refresh. Concurrent calls are coalesced via generation.
    func refresh() async {
        if preferences.horizonAlertsEnabled {
            notifications.requestAuthorizationIfNeeded()
        }
        refreshGeneration += 1
        let generation = refreshGeneration
        isRefreshing = true
        onStateChange?()
        defer {
            if generation == refreshGeneration {
                isRefreshing = false
                onStateChange?()
            }
        }

        var next = snapshots
        let previous = snapshots

        await withTaskGroup(of: (ProviderID, ProviderSnapshot).self) { group in
            for provider in providers where preferences.isEnabled(provider.id) {
                NSLog("[Cuprim] refresh %@", provider.id.rawValue)
                group.addTask {
                    do {
                        return (provider.id, try await provider.refresh())
                    } catch {
                        // Offline is machine-wide. Keep last-good usage instead of
                        // replacing every row with the system network string.
                        if ProviderStatusMapping.isOffline(error),
                           let last = previous[provider.id],
                           case .ok = last.status {
                            return (provider.id, last)
                        }
                        return (provider.id, ProviderStatusMapping.snapshot(for: provider.id, error: error))
                    }
                }
            }

            for await (id, snapshot) in group {
                // Stale generation: stop collecting; task group cancels remaining children on exit.
                guard generation == refreshGeneration else { break }
                next[id] = snapshot
            }
        }

        guard generation == refreshGeneration else { return }
        snapshots = next
        lastRefresh = .now
        cache.save(snapshots)
        for snapshot in next.values {
            guard case .ok = snapshot.status else { continue }
            for metric in snapshot.metrics {
                let samples = history.append(provider: snapshot.id, metric: metric, at: snapshot.fetchedAt)
                _ = QuotaHorizonEngine.estimate(samples: samples, now: snapshot.fetchedAt)
                if preferences.horizonAlertsEnabled {
                    notifications.scheduleIfNeeded(
                        provider: snapshot.id,
                        metric: metric,
                        snapshot: snapshot,
                        thresholds: [20, 5]
                    )
                }
            }
        }
        onStateChange?()
    }

    func horizon(for provider: ProviderID, metricID: String) -> QuotaHorizon {
        QuotaHorizonEngine.estimate(
            samples: history.samples(provider: provider, metricID: metricID),
            now: .now
        )
    }
}
