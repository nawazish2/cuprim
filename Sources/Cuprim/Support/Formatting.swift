import Foundation
import SwiftUI
import CuprimCore

extension QuotaFormatting {
    /// 4-band semantic meter colors using system semantic hues.
    static func meterColor(usedFraction: Double?) -> Color {
        guard let usedFraction else { return GlassChrome.textSecondary }
        switch Utilization.clamp01(usedFraction) {
        case ..<0.55:
            return Color.green
        case ..<0.80:
            return Color.yellow
        case ..<0.95:
            return Color.orange
        default:
            return Color.red
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
