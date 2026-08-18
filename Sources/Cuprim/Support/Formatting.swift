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
}
