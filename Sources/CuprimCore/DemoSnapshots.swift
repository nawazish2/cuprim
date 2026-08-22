import Foundation

/// Deterministic, redacted snapshots for website captures. Enable with `CUPRIM_DEMO=1`.
public enum DemoSnapshots {
    public static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["CUPRIM_DEMO"] == "1"
    }

    /// Synthetic history matching `all(at:)`, so demo captures show the same
    /// sparklines and projections a real install would. Each metric ramps
    /// linearly up to its current value over the preceding four hours.
    public static func history(at date: Date = .now) -> UsageHistory {
        var history = UsageHistory()
        let buckets = 48
        let step = TimeInterval(UsageHistory.bucketSeconds)
        let snapshots = all(at: date)

        for bucket in 0..<buckets {
            let progress = Double(bucket) / Double(buckets - 1)
            let at = date.addingTimeInterval(-step * Double(buckets - 1 - bucket))
            for id in ProviderID.allCases {
                guard var snapshot = snapshots[id] else { continue }
                snapshot.metrics = snapshot.metrics.map { metric in
                    var ramped = metric
                    // Start at 55% of the final value so the line has slope
                    // without implying the window just reset.
                    ramped.usedFraction = metric.usedFraction.map {
                        $0 * (0.55 + 0.45 * progress)
                    }
                    return ramped
                }
                history.record(snapshot: snapshot, at: at)
            }
        }
        return history
    }

    public static func all(at date: Date = .now) -> [ProviderID: ProviderSnapshot] {
        let resetSoon = date.addingTimeInterval(2 * 3600)
        let resetWeek = date.addingTimeInterval(5 * 86_400)
        return [
            .claude: ProviderSnapshot(
                id: .claude,
                planName: "Pro",
                metrics: [
                    Metric(id: "session", label: "5-hour limit", usedFraction: 0.42, resetsAt: resetSoon, detail: "42% used"),
                    Metric(id: "weekly", label: "Weekly limit", usedFraction: 0.18, resetsAt: resetWeek, detail: "18% used")
                ],
                status: .ok,
                fetchedAt: date
            ),
            .codex: ProviderSnapshot(
                id: .codex,
                planName: "Plus",
                metrics: [
                    Metric(id: "session", label: "Session limit", usedFraction: 0.61, resetsAt: resetSoon, detail: "61% of limit used"),
                    Metric(id: "weekly", label: "Weekly limit", usedFraction: 0.33, resetsAt: resetWeek, detail: "33% of limit used")
                ],
                status: .ok,
                fetchedAt: date
            ),
            .cursor: ProviderSnapshot(
                id: .cursor,
                planName: "Pro",
                metrics: [
                    Metric(id: "auto", label: "Auto", usedFraction: 0.27, resetsAt: resetWeek, detail: "27% used"),
                    Metric(id: "api", label: "API", usedFraction: 0.09, resetsAt: resetWeek, detail: "9% used"),
                    Metric(id: "total", label: "Total", usedFraction: 0.18, resetsAt: resetWeek, detail: "18% used")
                ],
                status: .ok,
                fetchedAt: date
            ),
            .grok: ProviderSnapshot(
                id: .grok,
                planName: "SuperGrok",
                metrics: [
                    Metric(id: "period", label: "Billing period", usedFraction: 0.54, resetsAt: resetWeek, detail: "54% used")
                ],
                status: .ok,
                fetchedAt: date
            )
        ]
    }
}
