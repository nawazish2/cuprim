import Foundation
import SwiftUI
import CuprimCore

extension QuotaFormatting {
    /// Calm semantic meter colors with enough contrast for the compact panel.
    static func meterColor(usedFraction: Double?) -> Color {
        guard let usedFraction else { return GlassChrome.textSecondary }
        switch Utilization.clamp01(usedFraction) {
        case ..<0.55:
            return Color(red: 0.24, green: 0.55, blue: 0.98)
        case ..<0.80:
            return Color(red: 0.96, green: 0.68, blue: 0.22)
        case ..<0.95:
            return Color(red: 0.95, green: 0.43, blue: 0.20)
        default:
            return Color(red: 0.96, green: 0.28, blue: 0.32)
        }
    }

    /// Short whisper label for last panel refresh (e.g. "just now").
    static func updatedLabel(for date: Date?, relativeTo now: Date = .now) -> String? {
        guard let date else { return nil }
        let seconds = now.timeIntervalSince(date)
        if seconds < 8 { return "Just now" }
        if seconds < 60 { return "\(Int(seconds))s ago" }
        if seconds < 3600 {
            let m = max(1, Int(seconds / 60))
            return "\(m)m ago"
        }
        if seconds < 86_400 {
            let h = max(1, Int(seconds / 3600))
            return "\(h)h ago"
        }
        return "Earlier"
    }
}
