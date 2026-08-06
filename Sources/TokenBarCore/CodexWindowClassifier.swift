import Foundation

/// Classifies Codex usage windows by duration (session / weekly / period).
public enum CodexWindowClassifier {
    public enum Kind: String, Sendable, Equatable {
        case session
        case weekly
        case period
        case primary
    }

    public static func kind(windowSeconds seconds: Double) -> Kind {
        if seconds > 0, seconds <= 6 * 3600 { return .session }
        if seconds > 6 * 3600, seconds <= 8 * 86_400 { return .weekly }
        if seconds > 8 * 86_400 { return .period }
        return .primary
    }

    public static func label(for kind: Kind) -> String {
        switch kind {
        case .session: "Session limit"
        case .weekly: "Weekly limit"
        case .period: "Period limit"
        case .primary: "Usage limit"
        }
    }
}
