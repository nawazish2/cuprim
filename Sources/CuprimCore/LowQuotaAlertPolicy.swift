import Foundation

/// Crossing policy for local low-quota alerts. Emits only the most urgent
/// newly reached remaining-percent threshold (5 before 20).
public enum LowQuotaAlertPolicy {
    public static let thresholds = [20, 5]

    /// Smallest remaining threshold that has been newly crossed.
    public static func newlyReachedThreshold(
        remainingPercent: Int,
        alreadySent: Set<Int>
    ) -> Int? {
        let reached = Set(thresholds.filter { remainingPercent <= $0 })
        let newly = reached.subtracting(alreadySent)
        return newly.min()
    }

    public static func remainingPercent(usedFraction: Double) -> Int {
        Utilization.remainingPercent(usedFraction: usedFraction)
    }
}
