import Foundation

/// Pure utilization math shared by providers and UI.
public enum Utilization {
    /// Clamp to 0…1.
    public static func clamp01(_ value: Double) -> Double {
        max(0, min(1, value))
    }

    /// Convert a **known whole-percent** field (0…100, where 1 means 1%) into a unit fraction.
    /// Use this for Codex `used_percent`, Cursor `*PercentUsed`, Claude Desktop `fh`/`sd`, Grok `creditUsagePercent`.
    public static func fraction(fromPercent percent: Double) -> Double {
        clamp01(percent / 100)
    }

    /// Dual-scale: values **strictly greater than 1** are treated as percent; values in 0…1 as unit fractions.
    /// Only for ambiguous APIs (e.g. Claude OAuth `utilization` may be either scale).
    /// - Warning: whole-percent inputs of `1` (1%) must **not** use this — use `fraction(fromPercent:)`.
    public static func fraction(fromRaw raw: Double) -> Double {
        if raw > 1 {
            return clamp01(raw / 100)
        }
        return clamp01(raw)
    }

    /// Remaining percent 0…100 from used fraction 0…1.
    public static func remainingPercent(usedFraction: Double) -> Int {
        max(0, min(100, Int(((1 - clamp01(usedFraction)) * 100).rounded())))
    }

    /// Used percent 0…100 from used fraction 0…1.
    public static func usedPercent(usedFraction: Double) -> Int {
        max(0, min(100, Int((clamp01(usedFraction) * 100).rounded())))
    }
}
