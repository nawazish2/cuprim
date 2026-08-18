import Foundation

public enum ProviderID: String, CaseIterable, Identifiable, Codable, Sendable {
    case claude
    case codex
    case cursor
    case grok
    case antigravity

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .cursor: "Cursor"
        case .grok: "Grok"
        case .antigravity: "Antigravity"
        }
    }

    public var systemImage: String {
        switch self {
        case .claude: "brain.head.profile"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .cursor: "cursorarrow.click.2"
        case .grok: "sparkles"
        case .antigravity: "point.3.filled.connected.trianglepath"
        }
    }
}

public struct Metric: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var label: String
    /// Fraction used in 0...1. Nil when unknown.
    public var usedFraction: Double?
    public var resetsAt: Date?
    /// Optional trailing value text (e.g. "$12 left").
    public var detail: String?
    /// Force showing the reset row even when `resetsAt` is nil.
    public var showsResetRow: Bool

    public init(
        id: String,
        label: String,
        usedFraction: Double? = nil,
        resetsAt: Date? = nil,
        detail: String? = nil,
        showsResetRow: Bool = true
    ) {
        self.id = id
        self.label = label
        self.usedFraction = usedFraction
        self.resetsAt = resetsAt
        self.detail = detail
        self.showsResetRow = showsResetRow
    }

    public var remainingFraction: Double? {
        guard let usedFraction else { return nil }
        return max(0, min(1, 1 - usedFraction))
    }

    public var usedPercent: Int? {
        guard let usedFraction else { return nil }
        return Int((Utilization.clamp01(usedFraction) * 100).rounded())
    }
}

/// Sanitized failure kind. Never carry raw HTTP bodies.
public enum ProviderFailureKind: String, Codable, Hashable, Sendable {
    case signedOut
    case sessionExpired
    case offline
    case timedOut
    case rateLimited
    case malformedResponse
    case unavailable

    public var userMessage: String {
        switch self {
        case .signedOut: "Not signed in"
        case .sessionExpired: "Session expired"
        case .offline: "Offline"
        case .timedOut: "Timed out"
        case .rateLimited: "Rate limited. Try again shortly."
        case .malformedResponse: "Couldn’t read usage data"
        case .unavailable: "Unavailable"
        }
    }

    public var isTransient: Bool {
        switch self {
        case .offline, .timedOut, .rateLimited, .unavailable:
            return true
        case .signedOut, .sessionExpired, .malformedResponse:
            return false
        }
    }

    public var hidesWhenSignedOut: Bool {
        self == .signedOut || self == .sessionExpired
    }
}

public enum ProviderStatus: Codable, Hashable, Sendable {
    case ok
    case failed(ProviderFailureKind)

    public var message: String? {
        switch self {
        case .ok: nil
        case .failed(let kind): kind.userMessage
        }
    }

    public var failureKind: ProviderFailureKind? {
        switch self {
        case .ok: nil
        case .failed(let kind): kind
        }
    }

    public var isSignedOut: Bool {
        if case .failed(let kind) = self { return kind.hidesWhenSignedOut }
        return false
    }
}

public struct ProviderSnapshot: Identifiable, Codable, Hashable, Sendable {
    public var id: ProviderID
    public var planName: String?
    public var metrics: [Metric]
    public var status: ProviderStatus
    public var fetchedAt: Date

    public init(
        id: ProviderID,
        planName: String? = nil,
        metrics: [Metric],
        status: ProviderStatus,
        fetchedAt: Date
    ) {
        self.id = id
        self.planName = planName
        self.metrics = metrics
        self.status = status
        self.fetchedAt = fetchedAt
    }

    public static func empty(_ id: ProviderID, status: ProviderStatus, at date: Date = .now) -> ProviderSnapshot {
        ProviderSnapshot(id: id, planName: nil, metrics: [], status: status, fetchedAt: date)
    }

    public static func failed(_ id: ProviderID, _ kind: ProviderFailureKind, at date: Date = .now) -> ProviderSnapshot {
        empty(id, status: .failed(kind), at: date)
    }
}

public protocol ProviderRuntime: Sendable {
    var id: ProviderID { get }
    func hasLocalCredentials() async -> Bool
    func refresh() async throws -> ProviderSnapshot
}

public enum ProviderError: Error, LocalizedError, Sendable {
    case signedOut
    case sessionExpired
    case http(Int)
    case decode
    case timedOut
    case rateLimited
    case unavailable
    case message(String)

    public var failureKind: ProviderFailureKind {
        switch self {
        case .signedOut: .signedOut
        case .sessionExpired: .sessionExpired
        case .http: .unavailable
        case .decode: .malformedResponse
        case .timedOut: .timedOut
        case .rateLimited: .rateLimited
        case .unavailable: .unavailable
        case .message: .unavailable
        }
    }

    public var errorDescription: String? {
        switch self {
        case .signedOut:
            return ProviderFailureKind.signedOut.userMessage
        case .sessionExpired:
            return ProviderFailureKind.sessionExpired.userMessage
        case .http(let code):
            return "HTTP \(code)"
        case .decode:
            return ProviderFailureKind.malformedResponse.userMessage
        case .timedOut:
            return ProviderFailureKind.timedOut.userMessage
        case .rateLimited:
            return ProviderFailureKind.rateLimited.userMessage
        case .unavailable:
            return ProviderFailureKind.unavailable.userMessage
        case .message(let text):
            return text
        }
    }
}
