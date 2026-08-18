import Foundation

/// One freshness rule shared by the store, dashboard, and menu-bar tooltip.
public enum StalePolicy {
    /// Stale after three missed refresh intervals, with a 6-minute floor.
    public static func thresholdMinutes(refreshMinutes: Int) -> Int {
        max(6, max(1, refreshMinutes) * 3)
    }

    public static func isStale(
        _ date: Date?,
        refreshMinutes: Int,
        relativeTo now: Date = .now
    ) -> Bool {
        guard let date else { return true }
        let threshold = TimeInterval(thresholdMinutes(refreshMinutes: refreshMinutes) * 60)
        return now.timeIntervalSince(date) > threshold
    }
}
