import Foundation

/// Maps thrown provider failures into a `ProviderSnapshot` status.
public enum ProviderStatusMapping {
    public static func snapshot(for id: ProviderID, error: Error, at date: Date = .now) -> ProviderSnapshot {
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
