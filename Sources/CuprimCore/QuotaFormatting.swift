import Foundation

public enum QuotaFormatting {
    public static func remainingLabel(usedFraction: Double?) -> String {
        guard let usedFraction else { return "—" }
        return "\(Utilization.remainingPercent(usedFraction: usedFraction))%"
    }

    public static func usedPercentLabel(usedFraction: Double?) -> String {
        guard let usedFraction else { return "—" }
        return "\(Utilization.usedPercent(usedFraction: usedFraction))%"
    }

    public static func relativeReset(for date: Date?, relativeTo now: Date = .now) -> String? {
        guard let date else { return nil }
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 { return "soon" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds > 86_400 ? [.day, .hour] : seconds > 3_600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: seconds)
    }

    public static func absoluteReset(for date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("d MMM h:mm a")
        return formatter.string(from: date)
    }

    /// Calendar-only absolute for panel cards: "Resets Aug 26".
    public static func shortCalendarReset(for date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return "Resets \(formatter.string(from: date))"
    }

    /// Nearby windows use a short countdown; farther windows use an absolute date when `absolute` is true.
    public static func resetLabel(for date: Date?, absolute: Bool = true, relativeTo now: Date = .now) -> String {
        guard let date else { return "" }
        let remaining = date.timeIntervalSince(now)
        if remaining <= 0 { return "Resets soon" }

        if remaining <= 3 * 86_400, let rel = relativeReset(for: date, relativeTo: now), !rel.isEmpty {
            return "Resets in \(rel)"
        }
        if absolute, let abs = absoluteReset(for: date) {
            return "Resets \(abs)"
        }
        if let rel = relativeReset(for: date, relativeTo: now), !rel.isEmpty {
            return "Resets in \(rel)"
        }
        return "Resets soon"
    }

    /// Card footer: countdown if ≤ 3 days, else short calendar date.
    public static func smartResetLabel(for date: Date?, relativeTo now: Date = .now) -> String {
        guard let date else { return "" }
        let remaining = date.timeIntervalSince(now)
        if remaining <= 0 { return "Resets soon" }
        if remaining <= 3 * 86_400, let rel = relativeReset(for: date, relativeTo: now), !rel.isEmpty {
            return "Resets in \(rel)"
        }
        if let short = shortCalendarReset(for: date) {
            return short
        }
        return "Resets soon"
    }

    /// Short age for last *successful* fetch (e.g. "just now").
    public static func updatedLabel(for date: Date?, relativeTo now: Date = .now) -> String? {
        guard let date else { return nil }
        let seconds = now.timeIntervalSince(date)
        if seconds < 8 { return "just now" }
        if seconds < 60 { return "\(Int(seconds))s ago" }
        if seconds < 3600 {
            let minutes = max(1, Int(seconds / 60))
            return "\(minutes)m ago"
        }
        if seconds < 86_400 {
            let hours = max(1, Int(seconds / 3600))
            return "\(hours)h ago"
        }
        return "earlier"
    }
}
