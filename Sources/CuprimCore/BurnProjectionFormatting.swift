import Foundation

/// Display copy for a burn-rate projection.
///
/// Returns `nil` whenever there is nothing worth saying, and the card renders
/// nothing at all — an "insufficient data" line would be clutter on a 300pt
/// panel, and the whole point of `BurnProjection.unknown` is that we decline to
/// guess rather than showing a hedged number.
public enum BurnProjectionFormatting {
    /// Below this, a "will reach N% at reset" line isn't telling the user
    /// anything they can act on.
    public static let interestingProjectedUse = 0.5

    public static func caption(for projection: BurnProjection) -> String? {
        switch projection {
        case .unknown:
            return nil

        case .withinLimit(let projectedUsedAtReset):
            guard projectedUsedAtReset >= interestingProjectedUse else { return nil }
            let percent = Utilization.usedPercent(usedFraction: projectedUsedAtReset)
            return "On track for ~\(percent)% by reset"

        case .exhausts(_, let beforeReset):
            guard let lead = compactDuration(beforeReset) else {
                return "At this rate, out right before reset"
            }
            return "At this rate, out \(lead) before reset"
        }
    }

    /// Compact "2h 15m" / "45m". Nil below a quarter hour, where the ETA is
    /// finer than the projection's own rounding and would imply false precision.
    static func compactDuration(_ interval: TimeInterval) -> String? {
        let minutes = Int((interval / 60).rounded())
        guard minutes >= 15 else { return nil }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder)m" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }
}
