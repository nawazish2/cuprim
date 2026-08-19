import Foundation

public enum MenuBarSeverity: String, Sendable, Equatable {
    case idle
    case warning
    case critical
    case error
    case refreshing
}

public enum MenuBarTooltip {
    /// One non-contradictory line. Remaining percent wins over “Limit reached”.
    public static func text(
        remainingPercent: Int?,
        severity: MenuBarSeverity
    ) -> String {
        switch severity {
        case .refreshing:
            if let remainingPercent {
                return "Cuprim · \(remainingPercent)% left · Refreshing"
            }
            return "Cuprim · Refreshing"
        case .error:
            return "Cuprim · Unavailable"
        case .idle, .warning, .critical:
            if let remainingPercent {
                return "Cuprim · \(remainingPercent)% left"
            }
            if severity == .critical {
                return "Cuprim · Limit reached"
            }
            if severity == .warning {
                return "Cuprim · High usage"
            }
            return "Cuprim"
        }
    }

    public static func severity(
        worstUsedFraction: Double?,
        hasVisibleError: Bool,
        hasVisibleOK: Bool,
        isRefreshing: Bool
    ) -> MenuBarSeverity {
        if isRefreshing { return .refreshing }
        if let worst = worstUsedFraction {
            if worst >= 0.95 { return .critical }
            if worst >= 0.80 { return .warning }
            // A healthy worst-case usage number can still be hiding a
            // provider that's failing entirely — surface that instead of
            // going quiet just because at least one other provider is fine.
            if hasVisibleError { return .warning }
            return .idle
        }
        if hasVisibleError {
            return hasVisibleOK ? .warning : .error
        }
        return .idle
    }
}
