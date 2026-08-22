import Foundation

/// Whether a metric stands alone or aggregates the others in its card.
public enum MetricKind: String, Hashable, Sendable {
    case window
    case total
}

public extension Metric {
    /// Derived from the stable `id`, never from display copy. Views used to
    /// decide this by string-matching `label`, which silently changes meaning
    /// whenever the label wording does.
    var kind: MetricKind {
        id.lowercased().contains("total") ? .total : .window
    }
}

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

    /// How a card should render reset times: one shared row when every metric
    /// resets at effectively the same moment, otherwise a row per metric.
    ///
    /// Compares instants with a tolerance rather than comparing *formatted
    /// labels*, which is what the dashboard used to do — that made the layout
    /// depend on the wording of `QuotaFormatting.smartResetLabel`.
    func resetPresentation(tolerance: TimeInterval = 60) -> ResetPresentation {
        let dates = metrics.compactMap(\.resetsAt)
        guard let earliest = dates.min(), let latest = dates.max() else {
            return ResetPresentation(shared: nil, perMetric: false)
        }
        if latest.timeIntervalSince(earliest) <= tolerance {
            return ResetPresentation(shared: earliest, perMetric: false)
        }
        return ResetPresentation(shared: nil, perMetric: dates.count > 1)
    }
}

public struct ResetPresentation: Equatable, Sendable {
    /// Non-nil when a single combined reset row is honest for every metric.
    public let shared: Date?
    /// True when metrics reset at genuinely different times.
    public let perMetric: Bool

    public init(shared: Date?, perMetric: Bool) {
        self.shared = shared
        self.perMetric = perMetric
    }
}