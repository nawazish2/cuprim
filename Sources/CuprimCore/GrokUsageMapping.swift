import Foundation

/// Parses Grok cli-chat-proxy billing JSON.
public enum GrokUsageMapping {
    public struct CreditsResponse: Decodable, Sendable {
        public var config: Config?

        public struct Config: Decodable, Sendable {
            public var currentPeriod: Period?
            public var creditUsagePercent: Double?
            public var isUnifiedBillingUser: Bool?
            public var billingPeriodEnd: String?

            public struct Period: Decodable, Sendable {
                public var end: String?
            }
        }
    }

    public static func snapshot(
        fromJSON data: Data,
        planName: String?,
        at date: Date = .now
    ) throws -> ProviderSnapshot {
        let decoded: CreditsResponse
        do {
            decoded = try JSONDecoder().decode(CreditsResponse.self, from: data)
        } catch {
            throw ProviderError.decode
        }
        guard let config = decoded.config else {
            throw ProviderError.decode
        }

        var metrics: [Metric] = []
        let periodEnd = ISO8601Parsing.date(from: config.billingPeriodEnd)
            ?? ISO8601Parsing.date(from: config.currentPeriod?.end)

        if let credits = config.creditUsagePercent {
            let fraction = Utilization.fraction(fromPercent: credits)
            // Labeled "period", not "weekly" — the reset date comes from the
            // billing period end, which isn't necessarily a weekly cadence.
            metrics.append(
                Metric(
                    id: "period",
                    label: "Billing period",
                    usedFraction: fraction,
                    resetsAt: periodEnd,
                    detail: "\(Utilization.usedPercent(usedFraction: fraction))% used",
                    showsResetRow: true
                )
            )
        }

        guard !metrics.isEmpty else {
            throw ProviderError.decode
        }

        let plan = planName ?? (config.isUnifiedBillingUser == true ? "SuperGrok" : nil)
        return ProviderSnapshot(
            id: .grok,
            planName: plan,
            metrics: metrics,
            status: .ok,
            fetchedAt: date
        )
    }
}
