import Foundation

/// Parses Codex `/wham/usage` JSON.
public enum CodexUsageMapping {
    public struct Response: Decodable, Sendable {
        public var planType: String?
        public var rateLimit: RateLimit?

        enum CodingKeys: String, CodingKey {
            case planType = "plan_type"
            case rateLimit = "rate_limit"
        }

        public struct RateLimit: Decodable, Sendable {
            public var primaryWindow: Window?
            public var secondaryWindow: Window?

            enum CodingKeys: String, CodingKey {
                case primaryWindow = "primary_window"
                case secondaryWindow = "secondary_window"
            }
        }

        public struct Window: Decodable, Sendable {
            public var usedPercent: Double?
            public var limitWindowSeconds: Double?
            public var resetAfterSeconds: Double?
            public var resetAt: Double?

            enum CodingKeys: String, CodingKey {
                case usedPercent = "used_percent"
                case limitWindowSeconds = "limit_window_seconds"
                case resetAfterSeconds = "reset_after_seconds"
                case resetAt = "reset_at"
            }
        }
    }

    public static func snapshot(fromJSON data: Data, at date: Date = .now) throws -> ProviderSnapshot {
        let decoded: Response
        do {
            decoded = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw ProviderError.decode
        }

        var windows: [(String, String, Response.Window)] = []
        if let primary = decoded.rateLimit?.primaryWindow {
            windows.append(classify(primary))
        }
        if let secondary = decoded.rateLimit?.secondaryWindow {
            windows.append(classify(secondary))
        }

        var seen = Set<String>()
        var metrics: [Metric] = []
        for (id, label, window) in windows {
            var metricID = id
            if seen.contains(metricID) {
                metricID = "\(id)-\(metrics.count)"
            }
            seen.insert(metricID)
            metrics.append(metric(id: metricID, label: label, window: window, now: date))
        }

        guard !metrics.isEmpty else {
            throw ProviderError.decode
        }

        return ProviderSnapshot(
            id: .codex,
            planName: PlanNameFormatting.prettyPlan(decoded.planType),
            metrics: metrics,
            status: .ok,
            fetchedAt: date
        )
    }

    private static func classify(_ window: Response.Window) -> (String, String, Response.Window) {
        let seconds = window.limitWindowSeconds ?? 0
        let kind = CodexWindowClassifier.kind(windowSeconds: seconds)
        return (kind.rawValue, CodexWindowClassifier.label(for: kind), window)
    }

    private static func metric(id: String, label: String, window: Response.Window, now: Date) -> Metric {
        // A field the server omitted is unknown, not "0% used" — defaulting
        // to 0 would render a confident, alert-suppressing green meter.
        let fraction = window.usedPercent.map(Utilization.fraction(fromPercent:))
        let resetsAt: Date?
        if let resetAt = window.resetAt {
            resetsAt = Date(timeIntervalSince1970: ISO8601Parsing.epochSeconds(resetAt))
        } else if let after = window.resetAfterSeconds {
            resetsAt = now.addingTimeInterval(after)
        } else {
            resetsAt = nil
        }
        return Metric(
            id: id,
            label: label,
            usedFraction: fraction,
            resetsAt: resetsAt,
            detail: fraction.map { "\(Utilization.usedPercent(usedFraction: $0))% of limit used" },
            showsResetRow: true
        )
    }
}
