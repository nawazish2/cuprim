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
    private let notifications: NotificationCoordinator
    private let preferences: PreferencesStore
    private let gate = RefreshGate()
    private var loopTask: Task<Void, Never>?
    private let providerTimeout: TimeInterval = 15

    var onStateChange: (() -> Void)?

    init(
        providers: [any ProviderRuntime] = [
            ClaudeProvider(),
            CodexProvider(),
            CursorProvider(),
            GrokProvider()
        ],
        cache: SnapshotCache = SnapshotCache(),
        notifications: NotificationCoordinator = NotificationCoordinator(),
        preferences: PreferencesStore
    ) {
        self.providers = providers
        self.cache = cache
        self.notifications = notifications
        self.preferences = preferences
        cache.deleteLegacyHistory()
        if DemoSnapshots.isEnabled {
            snapshots = DemoSnapshots.all()
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

    var visibleSnapshots: [ProviderSnapshot] {
        preferences.orderedProviders.compactMap { id in
            guard preferences.isEnabled(id) else { return nil }
            let presentation = presentation(for: id)
            if preferences.hideLoggedOutProviders, !preferences.showsFirstLaunchSetup {
                if case .signedOut = presentation { return nil }
            }
            if let snapshot = presentation.snapshot {
                return snapshot
            }
            return snapshots[id]
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
