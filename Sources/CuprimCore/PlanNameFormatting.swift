import Foundation

/// Normalizes provider-supplied plan identifiers (e.g. `pro_plus`, `FREE_TRIAL`)
/// into display copy, shared across all four provider mappings.
public enum PlanNameFormatting {
    public static func prettyPlan(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()
        if lower.contains("free") { return "Free" }
        if lower.contains("max") { return "Max" }
        if lower.contains("pro") { return "Pro" }
        if lower.contains("team") { return "Team" }
        // "pro_plus" -> "Pro Plus"; "free_trial" -> "Free Trial"
        return raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}
