import Foundation

/// How a newly fetched snapshot combines with last-good quota data.
public enum RefreshMergePolicy {
    /// Keep last-good meters on transient failures. Replace on success or
    /// durable failures (signed out, expired session, malformed).
    public static func merge(
        previous: ProviderSnapshot?,
        incoming: ProviderSnapshot
    ) -> ProviderSnapshot {
        if case .ok = incoming.status {
            // An `.ok` snapshot with no metrics is not real data — a
            // mapping returning that (e.g. a partially-decoded response)
            // must not wipe out the last real meters, if there are any.
            if incoming.metrics.isEmpty, let previous, case .ok = previous.status, !previous.metrics.isEmpty {
                return previous
            }
            return incoming
        }
        guard let kind = incoming.status.failureKind, kind.isTransient,
              let previous, case .ok = previous.status
        else {
            return incoming
        }
        return previous
    }

    public static func shouldAlert(from incoming: ProviderSnapshot) -> Bool {
        if case .ok = incoming.status { return true }
        return false
    }
}
