import Foundation
import SQLite3
import CuprimCore

struct CursorProvider: ProviderRuntime {
    let id: ProviderID = .cursor
    var http = HTTPClient()

    private let usageSummaryURL = URL(string: "https://cursor.com/api/usage-summary")!
    private let stripeURL = URL(string: "https://api2.cursor.sh/auth/full_stripe_profile")!

    func hasLocalCredentials() async -> Bool {
        loadAccessToken() != nil
    }

    func refresh() async throws -> ProviderSnapshot {
        guard let token = loadAccessToken() else {
            return .empty(.cursor, status: .notLoggedIn)
        }

        // Prefer usage-summary (richer plan percentages). Cookie form used by Cursor web.
        let cookie = "WorkosCursorSessionToken=::\(token)"
        let (data, response) = try await http.get(
            url: usageSummaryURL,
            headers: [
                "Cookie": cookie,
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X) Cuprim/0.1"
            ]
        )

        if response.statusCode == 401 || response.statusCode == 403 {
            return .empty(.cursor, status: .notLoggedIn)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw ProviderError.http(response.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        var snapshot = try mapSummary(data)

        // Plan name from stripe profile (Bearer works here).
        if let plan = try? await fetchPlanName(token: token) {
            snapshot.planName = plan
        }

        return snapshot
    }

    // MARK: - Auth (Cursor state.vscdb)

    private func loadAccessToken() -> String? {
        let path = NSString(
            string: "~/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
        ).expandingTildeInPath
        return readSQLiteValue(path: path, key: "cursorAuth/accessToken")
    }

    private func readSQLiteValue(path: String, key: String) -> String? {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }

        let sql = "SELECT value FROM ItemTable WHERE key = ? LIMIT 1;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        // SQLITE_TRANSIENT: copy the key; temporary bridge C-string must not use STATIC.
        let nsKey = key as NSString
        sqlite3_bind_text(statement, 1, nsKey.utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }

        if let cString = sqlite3_column_text(statement, 0) {
            return String(cString: cString)
        }
        return nil
    }

    // MARK: - Mapping

    private struct SummaryResponse: Decodable {
        var membershipType: String?
        var isUnlimited: Bool?
        var billingCycleStart: String?
        var billingCycleEnd: String?
        var individualUsage: IndividualUsage?
        var autoModelSelectedDisplayMessage: String?
        var namedModelSelectedDisplayMessage: String?

        struct IndividualUsage: Decodable {
            var plan: PlanBucket?
            var onDemand: OnDemandBucket?

            struct PlanBucket: Decodable {
                var enabled: Bool?
                var used: Double?
                var limit: Double?
                var remaining: Double?
                var totalPercentUsed: Double?
                var autoPercentUsed: Double?
                var apiPercentUsed: Double?
            }

            struct OnDemandBucket: Decodable {
                var enabled: Bool?
                var used: Double?
                var limit: Double?
            }
        }
    }

    private func mapSummary(_ data: Data) throws -> ProviderSnapshot {
        let decoded = try JSONDecoder().decode(SummaryResponse.self, from: data)
        var metrics: [Metric] = []
        let cycleReset = parseISO(decoded.billingCycleEnd)
        let plan = decoded.individualUsage?.plan

        // Cursor shows Auto, API, and Total only (no Plan / on-demand rows).
        if decoded.isUnlimited == true {
            metrics.append(
                Metric(
                    id: "total",
                    label: "Total",
                    usedFraction: 0,
                    resetsAt: cycleReset,
                    detail: "Unlimited",
                    showsResetRow: cycleReset != nil
                )
            )
        } else {
            let auto = normalizedPercent(plan?.autoPercentUsed)
                ?? percent(fromDisplay: decoded.autoModelSelectedDisplayMessage)
            let api = normalizedPercent(plan?.apiPercentUsed)
                ?? percent(fromDisplay: decoded.namedModelSelectedDisplayMessage)
            let total = normalizedPercent(plan?.totalPercentUsed)
                ?? combinedAverage(auto: auto, api: api)

            if let auto {
                metrics.append(
                    Metric(
                        id: "auto",
                        label: "Auto",
                        usedFraction: auto,
                        resetsAt: cycleReset,
                        detail: usedPercentDetail(auto),
                        showsResetRow: true
                    )
                )
            }

            if let api {
                metrics.append(
                    Metric(
                        id: "api",
                        label: "API",
                        usedFraction: api,
                        resetsAt: cycleReset,
                        detail: usedPercentDetail(api),
                        showsResetRow: true
                    )
                )
            }

            if let total {
                metrics.append(
                    Metric(
                        id: "total",
                        label: "Total",
                        usedFraction: total,
                        resetsAt: cycleReset,
                        detail: usedPercentDetail(total),
                        showsResetRow: true
                    )
                )
            }
        }

        return ProviderSnapshot(
            id: .cursor,
            planName: decoded.membershipType?.capitalized,
            metrics: metrics,
            status: metrics.isEmpty ? .error("No usage data") : .ok,
            fetchedAt: .now
        )
    }

    private func usedPercentDetail(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))% used"
    }

    private func combinedAverage(auto: Double?, api: Double?) -> Double? {
        switch (auto, api) {
        case let (a?, b?): return (a + b) / 2
        case let (a?, nil): return a
        case let (nil, b?): return b
        default: return nil
        }
    }

    private func parseISO(_ value: String?) -> Date? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) { return date }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

    private func percent(fromDisplay message: String?) -> Double? {
        guard let message else { return nil }
        // "You've used 5% of your included total usage"
        guard let range = message.range(of: #"(\d+(?:\.\d+)?)\s*%"#, options: .regularExpression) else {
            return nil
        }
        let number = message[range].replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        guard let value = Double(number) else { return nil }
        return max(0, min(1, value / 100))
    }

    /// Cursor sends values like `4.01` meaning 4.01% used (always percent scale).
    private func normalizedPercent(_ value: Double?) -> Double? {
        guard let value else { return nil }
        return Utilization.fraction(fromPercent: value)
    }

    private struct StripeProfile: Decodable {
        var membershipType: String?
        var individualMembershipType: String?
    }

    private func fetchPlanName(token: String) async throws -> String? {
        let (data, response) = try await http.get(
            url: stripeURL,
            headers: [
                "Authorization": "Bearer \(token)",
                "User-Agent": "Mozilla/5.0 Cuprim/0.1"
            ]
        )
        guard (200..<300).contains(response.statusCode) else { return nil }
        let profile = try JSONDecoder().decode(StripeProfile.self, from: data)
        return (profile.individualMembershipType ?? profile.membershipType)?.capitalized
    }
}
