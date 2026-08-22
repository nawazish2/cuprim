import Foundation

/// One usage reading inside a single quota window.
public struct BurnSample: Equatable, Sendable {
    public let at: Date
    public let usedFraction: Double

    public init(at: Date, usedFraction: Double) {
        self.at = at
        self.usedFraction = Utilization.clamp01(usedFraction)
    }
}

/// Why no projection is offered. Every one of these renders as *nothing* in the
/// UI rather than as a number — the same rule the provider mappings follow, where
/// an absent field is unknown and never a confident zero.
public enum BurnUnknownReason: String, Hashable, Sendable {
    /// Fewer readings than a slope can be fit to.
    case tooFewSamples
    /// Readings cover too little time to extrapolate from.
    case spanTooShort
    /// No provider-reported reset, so "before reset" has no meaning.
    case noResetTime
    /// The newest reading is too old, or the window has already reset.
    case stale
    /// Usage fell inside what we believe is one window — the window
    /// segmentation must be wrong, so any reassurance would be unfounded.
    case usageDecreased
    /// Already at the cap; there is nothing left to project.
    case alreadyExhausted
}

public enum BurnProjection: Equatable, Sendable {
    case unknown(BurnUnknownReason)
    /// Projected used fraction when the window resets, always < 1.
    case withinLimit(projectedUsedAtReset: Double)
    /// Projected to hit the cap at `at`, which is `beforeReset` earlier than
    /// the window would have reset on its own.
    case exhausts(at: Date, beforeReset: TimeInterval)
}

/// Conservative burn-rate forecast over one quota window.
public enum BurnRate {
    /// Slopes flatter than this (fraction per hour) are treated as flat. Below
    /// it, an ETA would be dominated by sampling noise.
    public static let flatSlopePerHour = 0.005

    /// ETAs are rounded to this, and rendered with a "~".
    public static let etaGranularity: TimeInterval = 15 * 60

    /// - Parameters:
    ///   - samples: readings from a **single** window. The caller slices by
    ///     window boundary; this function never extrapolates across a reset.
    ///   - resetsAt: provider-reported reset for that window.
    public static func project(
        samples: [BurnSample],
        resetsAt: Date?,
        now: Date = .now,
        minimumSamples: Int = 3,
        minimumSpan: TimeInterval = 15 * 60,
        staleAfter: TimeInterval = 30 * 60
    ) -> BurnProjection {
        let ordered = samples.sorted { $0.at < $1.at }
        guard ordered.count >= max(2, minimumSamples),
              let earliest = ordered.first,
              let latest = ordered.last
        else {
            return .unknown(.tooFewSamples)
        }

        guard latest.at.timeIntervalSince(earliest.at) >= minimumSpan else {
            return .unknown(.spanTooShort)
        }

        guard now.timeIntervalSince(latest.at) <= staleAfter else {
            return .unknown(.stale)
        }

        guard latest.usedFraction < 1 else {
            return .unknown(.alreadyExhausted)
        }

        guard let resetsAt else {
            return .unknown(.noResetTime)
        }

        // A reset already in the past means these readings describe a window
        // that is over; projecting from them would describe nothing.
        guard resetsAt > now else {
            return .unknown(.stale)
        }

        guard let slopePerHour = slopePerHour(ordered) else {
            return .unknown(.spanTooShort)
        }

        if slopePerHour < -flatSlopePerHour {
            return .unknown(.usageDecreased)
        }

        let hoursUntilReset = resetsAt.timeIntervalSince(latest.at) / 3_600

        if slopePerHour <= flatSlopePerHour {
            // Flat enough that the honest statement is "it stays about here".
            return .withinLimit(
                projectedUsedAtReset: Utilization.clamp01(latest.usedFraction)
            )
        }

        let remaining = 1 - latest.usedFraction
        let exhaustsAt = latest.at.addingTimeInterval(remaining / slopePerHour * 3_600)

        // Crossing exactly at the reset is not an exhaustion — the window
        // turns over at that instant.
        guard exhaustsAt < resetsAt else {
            let projected = latest.usedFraction + slopePerHour * hoursUntilReset
            return .withinLimit(projectedUsedAtReset: Utilization.clamp01(projected))
        }

        let rounded = roundToGranularity(exhaustsAt)
        return .exhausts(
            at: rounded,
            beforeReset: max(0, resetsAt.timeIntervalSince(rounded))
        )
    }

    /// Least-squares slope in fraction-per-hour. A two-point slope over
    /// two-minute polling is dominated by noise, which is what made the
    /// previous version of this feature confidently wrong.
    private static func slopePerHour(_ ordered: [BurnSample]) -> Double? {
        let origin = ordered[0].at.timeIntervalSince1970
        let xs = ordered.map { ($0.at.timeIntervalSince1970 - origin) / 3_600 }
        let ys = ordered.map(\.usedFraction)
        let count = Double(ordered.count)
        let meanX = xs.reduce(0, +) / count
        let meanY = ys.reduce(0, +) / count

        var covariance = 0.0
        var variance = 0.0
        for index in xs.indices {
            let dx = xs[index] - meanX
            covariance += dx * (ys[index] - meanY)
            variance += dx * dx
        }
        guard variance > 0 else { return nil }
        return covariance / variance
    }

    private static func roundToGranularity(_ date: Date) -> Date {
        let seconds = date.timeIntervalSince1970
        return Date(
            timeIntervalSince1970: (seconds / etaGranularity).rounded() * etaGranularity
        )
    }
}
