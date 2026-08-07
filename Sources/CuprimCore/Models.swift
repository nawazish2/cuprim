import Foundation

public enum ProviderID: String, CaseIterable, Identifiable, Codable, Sendable {
    case claude
    case codex
    case cursor
    case grok

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .cursor: "Cursor"
        case .grok: "Grok"
        }
    }

    public var systemImage: String {
        switch self {
        case .claude: "brain.head.profile"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .cursor: "cursorarrow.click.2"
        case .grok: "sparkles"
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

public enum ProviderStatus: Codable, Hashable, Sendable {
    case ok
    case notLoggedIn
    case error(String)

    public var message: String? {
        switch self {
        case .ok: nil
        case .notLoggedIn: "Not logged in"
        case .error(let message): message
        }
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
}

public protocol ProviderRuntime: Sendable {
    var id: ProviderID { get }
    func hasLocalCredentials() async -> Bool
    func refresh() async throws -> ProviderSnapshot
}

public enum ProviderError: Error, LocalizedError, Sendable {
    case notLoggedIn
    case http(Int, String)
    case decode(String)
    case message(String)

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Not logged in"
        case .http(let code, let body):
            return "HTTP \(code): \(body)"
        case .decode(let detail):
            return "Decode failed: \(detail)"
        case .message(let text):
            return text
        }
    }
}
