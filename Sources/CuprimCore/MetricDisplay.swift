import Foundation

public extension Metric {
    /// Standardized dashboard / menu-facing label from stable metric `id`.
    var displayLabel: String {
        let key = id.lowercased()
        if key.hasPrefix("session") || key.contains("5h") || key.contains("5-hour") {
            return "Current window"
        }
        if key.hasPrefix("weekly") {
            return "Weekly"
        }
        if key.hasPrefix("period") || key == "primary" {
            return "Period"
        }
        if key.hasPrefix("sonnet") {
            return "Sonnet"
        }
        if key.hasPrefix("auto") {
            return "Auto"
        }
        if key.hasPrefix("api") {
            return "API"
        }
        if key.hasPrefix("total") {
            return "Total"
        }
        if key.hasPrefix("daily") || key == "day" {
            return "Daily"
        }
        if key.hasPrefix("monthly") || key == "month" {
            return "Monthly"
        }
        // Fallback: strip trailing " limit"
        let trimmed = label
            .replacingOccurrences(of: " limit", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? label : trimmed
    }
}

public extension ProviderSnapshot {
    /// Worst-case used fraction across OK metrics.
    var worstUsedFraction: Double? {
        metrics.compactMap(\.usedFraction).map(Utilization.clamp01).max()
    }

    /// Whether any metric is exhausted (≥ 95% used).
    var isExhausted: Bool {
        guard case .ok = status else { return false }
        return metrics.contains { metric in
            guard let f = metric.usedFraction else { return false }
            return Utilization.clamp01(f) >= 0.95
        }
    }

    /// Soonest reset across metrics, if any.
    var nextResetAt: Date? {
        metrics.compactMap(\.resetsAt).sorted().first
    }
}

/// Glance status for the status menu (mock layout).
/// Name (title) · plan (subtitle) · status trailing right. Monochrome only.
public enum ProviderGlanceStatus {
    /// Trailing status (`13%`, `Limit Reached`, `Unavailable`).
    public static func line(for snapshot: ProviderSnapshot) -> String {
        switch snapshot.status {
        case .notLoggedIn:
            return "Not signed in"
        case .error:
            return "Unavailable"
        case .ok:
            guard let worst = snapshot.worstUsedFraction else {
                return "—"
            }
            if worst >= 0.95 {
                return "Limit Reached"
            }
            return "\(Utilization.usedPercent(usedFraction: worst))%"
        }
    }

    public static func statusChip(for snapshot: ProviderSnapshot) -> String {
        line(for: snapshot)
    }

    /// Bold title — provider name only.
    public static func menuTitle(for snapshot: ProviderSnapshot) -> String {
        snapshot.id.displayName
    }

    /// Plan under the name (when using a two-line row).
    public static func menuPlan(for snapshot: ProviderSnapshot) -> String? {
        guard let plan = snapshot.planName, !plan.isEmpty else { return nil }
        return plan
    }

    /// Compact left label: `Claude · Free` (one line with plan).
    public static func compactTitle(for snapshot: ProviderSnapshot) -> String {
        if let plan = menuPlan(for: snapshot) {
            return "\(menuTitle(for: snapshot)) · \(plan)"
        }
        return menuTitle(for: snapshot)
    }

    public static func menuStatus(for snapshot: ProviderSnapshot) -> String {
        line(for: snapshot)
    }

    /// Single-line fallback without columns.
    public static func menuRow(for snapshot: ProviderSnapshot) -> String {
        "\(compactTitle(for: snapshot)) · \(line(for: snapshot))"
    }
}