import Foundation

/// Maps thrown provider failures into a sanitized `ProviderSnapshot` status.
public enum ProviderStatusMapping {
    public static func isOffline(_ error: Error) -> Bool {
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                return true
            default:
                break
            }
        }
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain else { return false }
        switch ns.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDataNotAllowed,
             NSURLErrorInternationalRoamingOff:
            return true
        default:
            return false
        }
    }

    public static func isTimedOut(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let provider = error as? ProviderError, case .timedOut = provider { return true }
        if let url = error as? URLError {
            return url.code == .timedOut
        }
        let ns = error as NSError
        return ns.domain == NSURLErrorDomain && ns.code == NSURLErrorTimedOut
    }

    public static func kind(for error: Error) -> ProviderFailureKind {
        if isOffline(error) { return .offline }
        if isTimedOut(error) { return .timedOut }
        if let providerError = error as? ProviderError {
            return providerError.failureKind
        }
        return .unavailable
    }

    public static func snapshot(for id: ProviderID, error: Error, at date: Date = .now) -> ProviderSnapshot {
        .failed(id, kind(for: error), at: date)
    }
}
