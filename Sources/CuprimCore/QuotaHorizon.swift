import Foundation

/// A bounded, local usage sample used to estimate whether a quota will last
/// until its provider-reported reset time.
public struct UsageSample: Codable, Hashable, Sendable {
    public let timestamp: Date
    public let usedFraction: Double
    public let resetsAt: Date?

    public init(timestamp: Date, usedFraction: Double, resetsAt: Date?) {
        self.timestamp = timestamp
        self.usedFraction = Utilization.clamp01(usedFraction)
        self.resetsAt = resetsAt
    }
}

public enum QuotaHorizonState: String, Codable, Hashable, Sendable {
    case insufficientHistory
    case stableUntilReset
    case likelyToExhaust
}

public struct QuotaHorizon: Codable, Hashable, Sendable {
    public let state: QuotaHorizonState
    public let confidence: Double
    public let ratePerHour: Double?
    public let estimatedExhaustionAt: Date?
    public let resetAt: Date?

    public init(
        state: QuotaHorizonState,
        confidence: Double,
        ratePerHour: Double?,
        estimatedExhaustionAt: Date?,
        resetAt: Date?
    ) {
        self.state = state
        self.confidence = max(0, min(1, confidence))
        self.ratePerHour = ratePerHour
        self.estimatedExhaustionAt = estimatedExhaustionAt
        self.resetAt = resetAt
    }
}

/// Conservative linear forecast. It intentionally refuses to extrapolate from
/// sparse or cross-reset data, which is safer than presenting false precision.
public enum QuotaHorizonEngine {
    public static func estimate(
        samples: [UsageSample],
        now: Date = .now,
        minimumInterval: TimeInterval = 10 * 60
    ) -> QuotaHorizon {
        let ordered = samples.sorted { $0.timestamp < $1.timestamp }
        guard let latest = ordered.last else {
            return insufficient(resetAt: nil)
        }

        let reset = latest.resetsAt
        let sameWindow = ordered.filter { sample in
            guard let reset else { return sample.resetsAt == nil }
            return sample.resetsAt?.timeIntervalSince1970 == reset.timeIntervalSince1970
        }
        guard let first = sameWindow.first,
              sameWindow.count >= 2,
              latest.timestamp.timeIntervalSince(first.timestamp) >= minimumInterval
        else {
            return insufficient(resetAt: reset)
        }

        let elapsedHours = latest.timestamp.timeIntervalSince(first.timestamp) / 3_600
        guard elapsedHours > 0 else { return insufficient(resetAt: reset) }

        let delta = latest.usedFraction - first.usedFraction
        let rate = delta / elapsedHours
        guard rate > 0.001 else {
            return QuotaHorizon(
                state: .stableUntilReset,
                confidence: confidence(sampleCount: sameWindow.count, elapsedHours: elapsedHours),
                ratePerHour: max(0, rate),
                estimatedExhaustionAt: nil,
                resetAt: reset
            )
        }

        let remaining = max(0, 1 - latest.usedFraction)
        let exhaustion = latest.timestamp.addingTimeInterval((remaining / rate) * 3_600)
        let isBeforeReset = reset.map { exhaustion < $0 } ?? true
        let state: QuotaHorizonState = isBeforeReset ? .likelyToExhaust : .stableUntilReset
        return QuotaHorizon(
            state: state,
            confidence: confidence(sampleCount: sameWindow.count, elapsedHours: elapsedHours),
            ratePerHour: rate,
            estimatedExhaustionAt: isBeforeReset ? exhaustion : nil,
            resetAt: reset
        )
    }

    private static func insufficient(resetAt: Date?) -> QuotaHorizon {
        QuotaHorizon(
            state: .insufficientHistory,
            confidence: 0,
            ratePerHour: nil,
            estimatedExhaustionAt: nil,
            resetAt: resetAt
        )
    }

    private static func confidence(sampleCount: Int, elapsedHours: TimeInterval) -> Double {
        let sampleScore = min(1, Double(sampleCount) / 6)
        let timeScore = min(1, elapsedHours / 6)
        return min(1, 0.35 + sampleScore * 0.35 + timeScore * 0.30)
    }
}
