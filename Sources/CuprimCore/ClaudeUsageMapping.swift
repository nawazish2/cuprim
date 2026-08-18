import Foundation

/// Parses Claude OAuth usage JSON and Desktop plan-usage-history samples.
public enum ClaudeUsageMapping {
    public struct LiveWindow: Decodable, Sendable {
        public var utilization: Double?
        public var resetsAt: String?

        enum CodingKeys: String, CodingKey {
            case utilization
            case resetsAt = "resets_at"
        }
    }

    public struct LiveResponse: Decodable, Sendable {
        public var fiveHour: LiveWindow?
        public var sevenDay: LiveWindow?
        public var sevenDaySonnet: LiveWindow?

        enum CodingKeys: String, CodingKey {
            case fiveHour = "five_hour"
            case sevenDay = "seven_day"
            case sevenDaySonnet = "seven_day_sonnet"
        }
    }

    public struct DesktopSample: Sendable {
        public var fiveHourPercent: Double
        public var weeklyPercent: Double
        public var sampledAt: Date

        public init(fiveHourPercent: Double, weeklyPercent: Double, sampledAt: Date) {
            self.fiveHourPercent = fiveHourPercent
            self.weeklyPercent = weeklyPercent
            self.sampledAt = sampledAt
        }
    }

    public static func snapshot(
        fromLiveJSON data: Data,
        subscriptionHint: String?,
        at date: Date = .now
    ) throws -> ProviderSnapshot {
        let decoded: LiveResponse
        do {
            decoded = try JSONDecoder().decode(LiveResponse.self, from: data)
        } catch {
            throw ProviderError.decode
        }

        var metrics: [Metric] = []
        if let window = decoded.fiveHour {
            metrics.append(metric(id: "session", label: "5-hour limit", window: window))
        }
        if let window = decoded.sevenDay {
            metrics.append(metric(id: "weekly", label: "Weekly limit", window: window))
        }
        if let window = decoded.sevenDaySonnet {
            metrics.append(metric(id: "sonnet", label: "Sonnet weekly", window: window))
        }
        guard !metrics.isEmpty else {
            throw ProviderError.decode
        }

        return ProviderSnapshot(
            id: .claude,
            planName: prettyPlan(subscriptionHint),
            metrics: metrics,
            status: .ok,
            fetchedAt: date
        )
    }

    public static func desktopSample(fromHistoryJSON data: Data) -> DesktopSample? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let samples = root["samples"] as? [[String: Any]],
              let last = samples.last
        else { return nil }

        let usage = last["u"] as? [String: Any] ?? [:]
        let fh = jsonDouble(usage["fh"]) ?? 0
        let sd = jsonDouble(usage["sd"]) ?? 0
        let ms = jsonDouble(last["t"]) ?? (Date().timeIntervalSince1970 * 1000)
        return DesktopSample(
            fiveHourPercent: fh,
            weeklyPercent: sd,
            sampledAt: Date(timeIntervalSince1970: ms / 1000)
        )
    }

    public static func snapshot(fromDesktop sample: DesktopSample) -> ProviderSnapshot {
        let sessionFraction = Utilization.fraction(fromPercent: sample.fiveHourPercent)
        let weeklyFraction = Utilization.fraction(fromPercent: sample.weeklyPercent)
        let metrics = [
            Metric(
                id: "session",
                label: "5-hour limit",
                usedFraction: sessionFraction,
                resetsAt: nil,
                detail: "\(Int(sample.fiveHourPercent.rounded()))% used",
                showsResetRow: true
            ),
            Metric(
                id: "weekly",
                label: "Weekly limit",
                usedFraction: weeklyFraction,
                resetsAt: nil,
                detail: "\(Int(sample.weeklyPercent.rounded()))% used",
                showsResetRow: true
            )
        ]
        return ProviderSnapshot(
            id: .claude,
            planName: "Free",
            metrics: metrics,
            status: .ok,
            fetchedAt: sample.sampledAt
        )
    }

    public static func prettyPlan(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()
        if lower.contains("free") { return "Free" }
        if lower.contains("max") { return "Max" }
        if lower.contains("pro") { return "Pro" }
        if lower.contains("team") { return "Team" }
        return raw.capitalized
    }

    private static func metric(id: String, label: String, window: LiveWindow) -> Metric {
        let fraction = Utilization.fraction(fromRaw: window.utilization ?? 0)
        let usedPct = Int((fraction * 100).rounded())
        return Metric(
            id: id,
            label: label,
            usedFraction: fraction,
            resetsAt: ISO8601Parsing.date(from: window.resetsAt),
            detail: "\(usedPct)% used",
            showsResetRow: true
        )
    }

    private static func jsonDouble(_ any: Any?) -> Double? {
        switch any {
        case let n as Double: return n
        case let n as Int: return Double(n)
        case let n as NSNumber: return n.doubleValue
        case let s as String: return Double(s)
        default: return nil
        }
    }
}
