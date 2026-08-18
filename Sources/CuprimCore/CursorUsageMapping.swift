import Foundation

/// Parses Cursor usage-summary JSON.
public enum CursorUsageMapping {
    public struct SummaryResponse: Decodable, Sendable {
        public var membershipType: String?
        public var isUnlimited: Bool?
        public var billingCycleEnd: String?
        public var individualUsage: IndividualUsage?
        public var autoModelSelectedDisplayMessage: String?
        public var namedModelSelectedDisplayMessage: String?

        public struct IndividualUsage: Decodable, Sendable {
            public var plan: PlanBucket?

            public struct PlanBucket: Decodable, Sendable {
                public var totalPercentUsed: Double?
                public var autoPercentUsed: Double?
                public var apiPercentUsed: Double?
            }
        }
    }

    public static func snapshot(fromJSON data: Data, at date: Date = .now) throws -> ProviderSnapshot {
        let decoded: SummaryResponse
        do {
            decoded = try JSONDecoder().decode(SummaryResponse.self, from: data)
        } catch {
            throw ProviderError.decode
        }

        var metrics: [Metric] = []
        let cycleReset = ISO8601Parsing.date(from: decoded.billingCycleEnd)
        let plan = decoded.individualUsage?.plan

        if decoded.isUnlimited == true {
            metrics.append(
                Metric(
                    id: "total",
                    label: "Total",
                    usedFraction: 0,
                    resetsAt: cycleReset,
                    detail: "Unlimited",
                    showsResetRow: cycleReset != nil
                )
            )
        } else {
            let auto = normalizedPercent(plan?.autoPercentUsed)
                ?? percent(fromDisplay: decoded.autoModelSelectedDisplayMessage)
            let api = normalizedPercent(plan?.apiPercentUsed)
                ?? percent(fromDisplay: decoded.namedModelSelectedDisplayMessage)
            let total = normalizedPercent(plan?.totalPercentUsed)
                ?? combinedAverage(auto: auto, api: api)

            if let auto {
                metrics.append(metric(id: "auto", label: "Auto", fraction: auto, reset: cycleReset))
            }
            if let api {
                metrics.append(metric(id: "api", label: "API", fraction: api, reset: cycleReset))
            }
            if let total {
                metrics.append(metric(id: "total", label: "Total", fraction: total, reset: cycleReset))
            }
        }

        guard !metrics.isEmpty else {
            throw ProviderError.decode
        }

        return ProviderSnapshot(
            id: .cursor,
            planName: decoded.membershipType?.capitalized,
            metrics: metrics,
            status: .ok,
            fetchedAt: date
        )
    }

    private static func metric(id: String, label: String, fraction: Double, reset: Date?) -> Metric {
        Metric(
            id: id,
            label: label,
            usedFraction: fraction,
            resetsAt: reset,
            detail: "\(Int((fraction * 100).rounded()))% used",
            showsResetRow: true
        )
    }

    private static func combinedAverage(auto: Double?, api: Double?) -> Double? {
        switch (auto, api) {
        case let (a?, b?): return (a + b) / 2
        case let (a?, nil): return a
        case let (nil, b?): return b
        default: return nil
        }
    }

    private static func percent(fromDisplay message: String?) -> Double? {
        guard let message else { return nil }
        guard let range = message.range(of: #"(\d+(?:\.\d+)?)\s*%"#, options: .regularExpression) else {
            return nil
        }
        let number = message[range].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        guard let value = Double(number) else { return nil }
        return max(0, min(1, value / 100))
    }

    private static func normalizedPercent(_ value: Double?) -> Double? {
        guard let value else { return nil }
        return Utilization.fraction(fromPercent: value)
    }
}
