import Foundation
import Observation
import TokenBarCore

@MainActor
@Observable
final class UsageStore {
    private(set) var snapshots: [ProviderID: ProviderSnapshot] = [:]
    private(set) var isRefreshing = false
    private(set) var lastRefresh: Date?

    private let providers: [any ProviderRuntime]
    private let cache: SnapshotCache
    private let preferences: PreferencesStore
    private var loopTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init(
        providers: [any ProviderRuntime] = [
            ClaudeProvider(),
            CodexProvider(),
            CursorProvider(),
            GrokProvider()
        ],
        cache: SnapshotCache = SnapshotCache(),
        preferences: PreferencesStore
    ) {
        self.providers = providers
        self.cache = cache
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
        refreshGeneration += 1
        let generation = refreshGeneration
        isRefreshing = true
        defer {
            if generation == refreshGeneration {
                isRefreshing = false
            }
        }

        var next = snapshots

        await withTaskGroup(of: (ProviderID, ProviderSnapshot).self) { group in
            for provider in providers where preferences.isEnabled(provider.id) {
                group.addTask {
                    do {
                        return (provider.id, try await provider.refresh())
                    } catch {
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
    }
}
