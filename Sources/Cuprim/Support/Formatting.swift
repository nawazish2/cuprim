import AppKit
import Foundation
import SwiftUI
import CuprimCore

extension QuotaFormatting {
    /// Calm semantic meter colors with enough contrast for the compact panel.
    /// Colors interpolate continuously between severity stops instead of
    /// snapping at a hard threshold, so two nearby percentages (e.g. 54%
    /// and 60%) render as nearby hues rather than jumping across a cliff.
    static func meterColor(usedFraction: Double?) -> Color {
        guard let usedFraction else { return GlassChrome.textSecondary }
        let fraction = Utilization.clamp01(usedFraction)
        let stops: [(position: Double, color: Color)] = [
            (0.0, GlassChrome.usageBlue),
            (0.55, GlassChrome.usageBlue),
            (0.70, GlassChrome.usageAmber),
            (0.85, GlassChrome.usageOrange),
            (0.95, GlassChrome.usageRed),
            (1.0, GlassChrome.usageRed)
        ]
        for index in 1..<stops.count {
            let lower = stops[index - 1]
            let upper = stops[index]
            guard fraction <= upper.position else { continue }
            let span = upper.position - lower.position
            let t = span > 0 ? (fraction - lower.position) / span : 0
            return lower.color.mixed(with: upper.color, amount: t)
        }
        return stops.last!.color
    }
}

private extension Color {
    /// Linear RGB blend toward `other`. `amount` 0 returns self, 1 returns `other`.
    func mixed(with other: Color, amount: Double) -> Color {
        let t = Utilization.clamp01(amount)
        let a = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        let b = NSColor(other).usingColorSpace(.deviceRGB) ?? NSColor(other)
        return Color(
            red: a.redComponent + (b.redComponent - a.redComponent) * t,
            green: a.greenComponent + (b.greenComponent - a.greenComponent) * t,
            blue: a.blueComponent + (b.blueComponent - a.blueComponent) * t
        )
    }
}
