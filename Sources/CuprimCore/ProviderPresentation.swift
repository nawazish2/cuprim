import Foundation

/// UI-facing per-provider state. Every case answers what happened, whether
/// last-good data is shown, and what the user can do next.
public enum ProviderPresentation: Equatable, Sendable {
    case loading
    case ready(ProviderSnapshot)
    case stale(ProviderSnapshot, failure: ProviderFailureKind?)
    case signedOut(ProviderFailureKind)
    case failed(ProviderFailureKind, lastGood: ProviderSnapshot?)

    public var snapshot: ProviderSnapshot? {
        switch self {
        case .loading:
            return nil
        case .ready(let snapshot), .stale(let snapshot, _):
            return snapshot
        case .signedOut:
            return nil
        case .failed(_, let lastGood):
            return lastGood
        }
    }

    public var failureKind: ProviderFailureKind? {
        switch self {
        case .loading, .ready:
            return nil
        case .stale(_, let failure):
            return failure
        case .signedOut(let kind), .failed(let kind, _):
            return kind
        }
    }

    public static func make(
        id: ProviderID,
        lastGood: ProviderSnapshot?,
        lastFailure: ProviderFailureKind?,
        isRefreshing: Bool,
        refreshMinutes: Int,
        now: Date = .now
    ) -> ProviderPresentation {
        if let lastGood, case .ok = lastGood.status {
            let stale = StalePolicy.isStale(lastGood.fetchedAt, refreshMinutes: refreshMinutes, relativeTo: now)
            if stale || (lastFailure?.isTransient == true) {
                return .stale(lastGood, failure: lastFailure)
            }
            return .ready(lastGood)
        }

        if let lastFailure {
            if lastFailure.hidesWhenSignedOut {
                return .signedOut(lastFailure)
            }
            return .failed(lastFailure, lastGood: lastGood)
        }

        if isRefreshing {
            return .loading
        }
        return .failed(.unavailable, lastGood: lastGood)
    }
}
