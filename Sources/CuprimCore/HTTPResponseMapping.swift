import Foundation

/// Maps HTTP status codes to sanitized failure kinds. Never include response bodies.
public enum HTTPResponseMapping {
    public static let maxResponseBytes = 1_048_576

    public static func kind(
        statusCode: Int,
        credentialsPresent: Bool = false,
        sessionKnownExpired: Bool = false
    ) -> ProviderFailureKind {
        switch statusCode {
        case 429:
            return .rateLimited
        case 401, 403:
            if sessionKnownExpired || credentialsPresent {
                return .sessionExpired
            }
            return .signedOut
        default:
            return .unavailable
        }
    }

    public static func error(
        statusCode: Int,
        credentialsPresent: Bool = false,
        sessionKnownExpired: Bool = false
    ) -> ProviderError {
        switch kind(
            statusCode: statusCode,
            credentialsPresent: credentialsPresent,
            sessionKnownExpired: sessionKnownExpired
        ) {
        case .signedOut: return .signedOut
        case .sessionExpired: return .sessionExpired
        case .rateLimited: return .rateLimited
        case .timedOut: return .timedOut
        default: return .http(statusCode)
        }
    }

    public static func throwIfFailed(
        _ response: HTTPURLResponse,
        credentialsPresent: Bool = false,
        sessionKnownExpired: Bool = false
    ) throws {
        let code = response.statusCode
        guard !(200..<300).contains(code) else { return }
        throw error(
            statusCode: code,
            credentialsPresent: credentialsPresent,
            sessionKnownExpired: sessionKnownExpired
        )
    }
}
