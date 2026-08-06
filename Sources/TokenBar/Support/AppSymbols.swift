import Foundation
import TokenBarCore

/// SF Symbols used across TokenBar for a native macOS look.
enum AppSymbols {
    /// Menu bar + panel header mark.
    static let app = "gauge.with.dots.needle.67percent"
    /// Fallback if a newer symbol is missing on older SDKs.
    static let appFallback = "gauge.medium"
    static let refresh = "arrow.clockwise"
    static let overviewTab = "square.grid.2x2.fill"
    static let settings = "gearshape"
    static let notSignedIn = "person.crop.circle.badge.questionmark"
    static let error = "exclamationmark.triangle.fill"
}
