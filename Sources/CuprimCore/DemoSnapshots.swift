import Foundation

/// Deterministic, redacted snapshots for website captures. Enable with `CUPRIM_DEMO=1`.
public enum DemoSnapshots {
    public static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["CUPRIM_DEMO"] == "1"
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
