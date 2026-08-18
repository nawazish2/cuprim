import Foundation

/// Parses Antigravity `RetrieveUserQuotaSummary` / `GetUserStatus` JSON.
public enum AntigravityQuotaMapping {
    public static func metrics(fromSummaryJSON data: Data) throws -> [Metric] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ProviderError.decode
        }
        let groups = (root["response"] as? [String: Any])?["groups"] as? [[String: Any]]
            ?? root["groups"] as? [[String: Any]]
            ?? []

        var metrics: [Metric] = []
        for group in groups {
            let groupName = (group["displayName"] as? String) ?? "Usage"
            let buckets = group["buckets"] as? [[String: Any]] ?? []
            for bucket in buckets {
                guard let remaining = remainingFraction(in: bucket) else { continue }
                let used = Utilization.clamp01(1 - remaining)
                let bucketID = (bucket["bucketId"] as? String) ?? "bucket"
                let window = (bucket["window"] as? String) ?? ""
                metrics.append(
                    Metric(
                        id: "\(sanitized(groupName)).\(bucketID)",
                        label: metricLabel(group: groupName, window: window),
                        usedFraction: used,
                        resetsAt: ISO8601Parsing.date(fromAny: bucket["resetTime"]),
                        detail: nil,
                        showsResetRow: true
                    )
                )
            }
        }
        return metrics
    }

    public static func planName(fromStatusJSON data: Data) -> String? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let status = root["userStatus"] as? [String: Any] ?? root
        let plan = ((status["planStatus"] as? [String: Any])?["planInfo"] as? [String: Any])?["planName"] as? String
        let trimmed = plan?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func remainingFraction(in bucket: [String: Any]) -> Double? {
        if let value = bucket["remainingFraction"] as? Double { return value }
        if let value = bucket["remainingFraction"] as? Int { return Double(value) }
        if let nested = bucket["remaining"] as? [String: Any] {
            if let value = nested["remainingFraction"] as? Double { return value }
            if let value = nested["remainingFraction"] as? Int { return Double(value) }
        }
        return nil
    }

    private static func metricLabel(group: String, window: String) -> String {
        let family: String
        let lower = group.lowercased()
        if lower.contains("gemini") {
            family = "Gemini"
        } else if lower.contains("claude") || lower.contains("gpt") {
            family = "Claude + GPT"
        } else {
            family = group
        }
        if window.lowercased().contains("week") {
            return "\(family) weekly"
        }
        if window.lowercased().contains("hour") || window.lowercased().contains("session") {
            return "\(family) session"
        }
        return family
    }

    private static func sanitized(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: " ", with: "-")
    }
}
