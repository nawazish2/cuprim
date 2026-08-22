import Foundation

/// Normalizes provider-supplied plan identifiers (e.g. `pro_plus`, `FREE_TRIAL`)
/// into display copy, shared across all four provider mappings.
public enum PlanNameFormatting {
    public static func prettyPlan(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()
        let words = Set(lower.split(whereSeparator: { $0 == "_" || $0 == "-" || $0 == " " }))
        if words == ["free"] { return "Free" }
        if words == ["max"] { return "Max" }
        if words == ["pro"] { return "Pro" }
        if words == ["team"] { return "Team" }
        // "pro_plus" -> "Pro Plus"; "free_trial" -> "Free Trial"
        return raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
