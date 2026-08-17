import Foundation

/// Maps thrown provider failures into a `ProviderSnapshot` status.
public enum ProviderStatusMapping {
    public static let offlineMessage = "Offline"

    public static func isOffline(_ error: Error) -> Bool {
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                return true
            default:
                return false
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

    public static func snapshot(for id: ProviderID, error: Error, at date: Date = .now) -> ProviderSnapshot {
        if isOffline(error) {
            return .empty(id, status: .error(offlineMessage), at: date)
        }
        if let providerError = error as? ProviderError {
            switch providerError {
            case .notLoggedIn:
                return .empty(id, status: .notLoggedIn, at: date)
            default:
                return .empty(id, status: .error(providerError.localizedDescription), at: date)
            }
        }
        // Some layers throw plain errors with the same message as notLoggedIn.
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           description == ProviderError.notLoggedIn.localizedDescription {
            return .empty(id, status: .notLoggedIn, at: date)
        }
        return .empty(id, status: .error(error.localizedDescription), at: date)
    }
}
