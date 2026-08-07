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

/// Glance status phrases for the status menu (no multi-metric dump).
/// Layout: provider name (title) · plan (subtitle) · status trailing right. Monochrome only.
public enum ProviderGlanceStatus {
    /// Trailing / primary status label (no emoji, no color markers).
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
            let pct = Utilization.usedPercent(usedFraction: worst)
            if worst >= 0.95 {
                return "Limit Reached"
            }
            return "\(pct)%"
        }
    }

    /// @available — same as `line` (kept for call sites that used statusChip).
    public static func statusChip(for snapshot: ProviderSnapshot) -> String {
        line(for: snapshot)
    }

    public static func menuTitle(for snapshot: ProviderSnapshot) -> String {
        snapshot.id.displayName
    }

    /// Plan only under the name (right-side status is composed separately).
    public static func menuSubtitle(for snapshot: ProviderSnapshot) -> String? {
        if let plan = snapshot.planName, !plan.isEmpty {
            return plan
        }
        return nil
    }

    /// Plan string for subtitle, or empty when absent (keeps row heights when set as "").
    public static func menuPlanLabel(for snapshot: ProviderSnapshot) -> String {
        menuSubtitle(for: snapshot) ?? ""
    }
}
