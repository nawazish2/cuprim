import Foundation
import Security
import TokenBarCore

struct ClaudeProvider: ProviderRuntime {
    let id: ProviderID = .claude
    var http = HTTPClient()

    private let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    func hasLocalCredentials() async -> Bool {
        loadOAuth() != nil || loadDesktopUsageSample() != nil
    }

    func refresh() async throws -> ProviderSnapshot {
        // 1) Claude Code OAuth → live Session / Weekly + exact reset times
        if let oauth = loadOAuth() {
            if let accessToken = oauth.accessToken, !accessToken.isEmpty {
                do {
                    return try await fetchLiveUsage(accessToken: accessToken, oauth: oauth)
                } catch ProviderError.notLoggedIn {
                    // Fall through to Desktop sample / not logged in.
                } catch {
                    // Signed in but API failed — prefer Desktop meters over a false "not logged in".
                    if let desktop = loadDesktopUsageSample() {
                        return mapDesktopUsage(desktop)
                    }
                    return .empty(.claude, status: .error(error.localizedDescription))
                }
            }
        }

        // 2) Claude Desktop free/pro plan meters written locally (no Claude Code login required)
        if let desktop = loadDesktopUsageSample() {
            return mapDesktopUsage(desktop)
        }

        return .empty(.claude, status: .notLoggedIn)
    }

    // MARK: - Live OAuth usage

    private func fetchLiveUsage(accessToken: String, oauth: ClaudeOAuth) async throws -> ProviderSnapshot {
        let (data, response) = try await http.get(
            url: usageURL,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "TokenBar/0.1"
            ]
        )

        guard (200..<300).contains(response.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if response.statusCode == 401 || response.statusCode == 403 {
                throw ProviderError.notLoggedIn
            }
            if response.statusCode == 429 {
                // Rate limited — fall through to Desktop local meters if available
                if let desktop = loadDesktopUsageSample() {
                    return mapDesktopUsage(desktop)
                }
                throw ProviderError.message("Claude usage rate limited — try again shortly")
            }
            throw ProviderError.http(response.statusCode, body)
        }

        return try mapLiveUsage(data, subscriptionHint: oauth.subscriptionType)
    }

    private struct UsageResponse: Decodable {
        struct Window: Decodable {
            var utilization: Double?
            var resetsAt: String?

            enum CodingKeys: String, CodingKey {
                case utilization
                case resetsAt = "resets_at"
            }
        }

        var fiveHour: Window?
        var sevenDay: Window?
        var sevenDaySonnet: Window?
        var extraUsage: ExtraUsage?

        enum CodingKeys: String, CodingKey {
            case fiveHour = "five_hour"
            case sevenDay = "seven_day"
            case sevenDaySonnet = "seven_day_sonnet"
            case extraUsage = "extra_usage"
        }

        struct ExtraUsage: Decodable {
            var utilization: Double?
            var used: Double?
            var limit: Double?
        }
    }

    private func mapLiveUsage(_ data: Data, subscriptionHint: String?) throws -> ProviderSnapshot {
        let decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
        var metrics: [Metric] = []

        // Free / Pro / Max all expose these windows when available.
        if let window = decoded.fiveHour {
            metrics.append(metric(id: "session", label: "5-hour limit", window: window))
        }
        if let window = decoded.sevenDay {
            metrics.append(metric(id: "weekly", label: "Weekly limit", window: window))
        }
        if let window = decoded.sevenDaySonnet {
            metrics.append(metric(id: "sonnet", label: "Sonnet weekly", window: window))
        }

        // Always surface the two core free-plan windows even if API omitted one as null
        // (show 0% with unknown reset rather than hiding the row entirely when both missing).
        if metrics.isEmpty {
            throw ProviderError.message("No Claude limit windows in response")
        }

        return ProviderSnapshot(
            id: .claude,
            planName: prettyPlan(subscriptionHint),
            metrics: metrics,
            status: .ok,
            fetchedAt: .now
        )
    }

    private func metric(id: String, label: String, window: UsageResponse.Window) -> Metric {
        let raw = window.utilization ?? 0
        // API may return 0–1 or 0–100
        let fraction = Utilization.fraction(fromRaw: raw)
        let usedPct = Int((fraction * 100).rounded())
        return Metric(
            id: id,
            label: label,
            usedFraction: fraction,
            resetsAt: parseISO(window.resetsAt),
            detail: "\(usedPct)% used",
            showsResetRow: true
        )
    }

    // MARK: - Claude Desktop local free/pro meters

    /// Desktop writes rolling samples: u.fh = 5-hour %, u.sd = 7-day %.
    private struct DesktopUsageSample {
        var fiveHourPercent: Double
        var weeklyPercent: Double
        var sampledAt: Date
    }

    private func loadDesktopUsageSample() -> DesktopUsageSample? {
        let path = NSString(
            string: "~/Library/Application Support/Claude/plan-usage-history.json"
        ).expandingTildeInPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let samples = root["samples"] as? [[String: Any]],
              let last = samples.last
        else { return nil }

        let usage = last["u"] as? [String: Any] ?? [:]
        // Values are whole percents (e.g. 12 = 12%).
        let fh = doubleValue(usage["fh"]) ?? 0
        let sd = doubleValue(usage["sd"]) ?? 0
        let ms = doubleValue(last["t"]) ?? (Date().timeIntervalSince1970 * 1000)
        return DesktopUsageSample(
            fiveHourPercent: fh,
            weeklyPercent: sd,
            sampledAt: Date(timeIntervalSince1970: ms / 1000)
        )
    }

    private func mapDesktopUsage(_ sample: DesktopUsageSample) -> ProviderSnapshot {
        // Desktop history has utilization % only (no official resets_at).
        // Show Free plan 5h + weekly meters; exact reset needs Claude Code OAuth.
        // Desktop fh/sd are whole percents (12 = 12%); never dual-scale.
        let sessionFraction = Utilization.fraction(fromPercent: sample.fiveHourPercent)
        let weeklyFraction = Utilization.fraction(fromPercent: sample.weeklyPercent)

        let metrics = [
            Metric(
                id: "session",
                label: "5-hour limit",
                usedFraction: sessionFraction,
                resetsAt: nil,
                detail: "\(Int(sample.fiveHourPercent.rounded()))% used · Free plan",
                showsResetRow: true
            ),
            Metric(
                id: "weekly",
                label: "Weekly limit",
                usedFraction: weeklyFraction,
                resetsAt: nil,
                detail: "\(Int(sample.weeklyPercent.rounded()))% used · Free plan",
                showsResetRow: true
            )
        ]

        return ProviderSnapshot(
            id: .claude,
            planName: "Free",
            metrics: metrics,
            status: .ok,
            fetchedAt: sample.sampledAt
        )
    }

    private func doubleValue(_ any: Any?) -> Double? {
        switch any {
        case let n as Double: return n
        case let n as Int: return Double(n)
        case let n as NSNumber: return n.doubleValue
        case let s as String: return Double(s)
        default: return nil
        }
    }

    private func prettyPlan(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()
        if lower.contains("free") { return "Free" }
        if lower.contains("max") { return "Max" }
        if lower.contains("pro") { return "Pro" }
        if lower.contains("team") { return "Team" }
        return raw.capitalized
    }

    // MARK: - Auth (Claude Code)

    private struct ClaudeOAuth: Codable {
        var accessToken: String?
        var refreshToken: String?
        var expiresAt: Double?
        var subscriptionType: String?
        var scopes: [String]?
    }

    private struct ClaudeCredentialsFile: Codable {
        var claudeAiOauth: ClaudeOAuth?
    }

    private func loadOAuth() -> ClaudeOAuth? {
        if let keychain = loadKeychainCredentials() { return keychain }
        if let file = loadFileCredentials() { return file }
        if let env = ProcessInfo.processInfo.environment["CLAUDE_CODE_OAUTH_TOKEN"], !env.isEmpty {
            return ClaudeOAuth(
                accessToken: env,
                refreshToken: nil,
                expiresAt: nil,
                subscriptionType: nil,
                scopes: nil
            )
        }
        return nil
    }

    private func loadFileCredentials() -> ClaudeOAuth? {
        let home = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"]
            ?? NSString(string: "~/.claude").expandingTildeInPath
        let path = (home as NSString).appendingPathComponent(".credentials.json")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let file = try? JSONDecoder().decode(ClaudeCredentialsFile.self, from: data),
              let oauth = file.claudeAiOauth,
              oauth.accessToken?.isEmpty == false
        else { return nil }
        return oauth
    }

    private func loadKeychainCredentials() -> ClaudeOAuth? {
        // Claude Code (current + legacy service names)
        let services = [
            "Claude Code-credentials",
            "Claude Code"
        ]
        for service in services {
            if let text = readKeychain(service: service),
               let data = text.data(using: .utf8),
               let file = try? JSONDecoder().decode(ClaudeCredentialsFile.self, from: data),
               let oauth = file.claudeAiOauth,
               oauth.accessToken?.isEmpty == false {
                return oauth
            }
        }
        return nil
    }

    private func readKeychain(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func parseISO(_ value: String?) -> Date? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) { return date }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

}
