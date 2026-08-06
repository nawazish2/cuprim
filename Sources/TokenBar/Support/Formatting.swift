import Foundation
import SwiftUI
import TokenBarCore

// Re-export pure formatting for app code; add UI colors here.

extension QuotaFormatting {
    /// Status colors for meters — high contrast on dark glass.
    static func meterColor(usedFraction: Double?) -> Color {
        guard let usedFraction else { return .secondary }
        switch Utilization.clamp01(usedFraction) {
        case ..<0.55:
            return Color(red: 0.42, green: 0.86, blue: 0.55)
        case ..<0.80:
            return Color(red: 1.0, green: 0.78, blue: 0.28)
        default:
            return Color(red: 1.0, green: 0.48, blue: 0.44)
        }
    }
}
