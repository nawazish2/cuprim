import Foundation
import CuprimCore

/// Grok Build CLI quotas from `~/.grok/auth.json` + cli-chat-proxy billing.
struct GrokProvider: ProviderRuntime {
    let id: ProviderID = .grok
    var http = HTTPClient()

    private let creditsURL = URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits")!
    private let settingsURL = URL(string: "https://cli-chat-proxy.grok.com/v1/settings")!
    private let refreshURL = URL(string: "https://auth.x.ai/oauth2/token")!
    private let defaultClientID = "b1a00492-073a-47ea-816f-4c329264a828"
    private let tokenAuthHeader = "xai-grok-cli"

    func hasLocalCredentials() async -> Bool {
        loadAuth() != nil
    }

    func refresh() async throws -> ProviderSnapshot {
        guard var auth = loadAuth() else {
            return .empty(.grok, status: .notLoggedIn)
        }

        if needsRefresh(auth), let refreshed = try? await refreshAccessToken(auth) {
            auth = refreshed
            persist(auth)
        }

        do {
            return try await fetchCredits(auth: auth)
        } catch {
            // One retry after forced refresh on auth failure.
            if let refreshed = try? await refreshAccessToken(auth) {
                persist(refreshed)
                return try await fetchCredits(auth: refreshed)
            }
            throw error
        }
    }

    // MARK: - API

    private func fetchCredits(auth: LoadedAuth) async throws -> ProviderSnapshot {
        let token = auth.accessToken
        let (data, response) = try await http.get(
            url: creditsURL,
            headers: authHeaders(token: token)
        )

        if response.statusCode == 401 || response.statusCode == 403 {
            throw ProviderError.notLoggedIn
        }
        guard (200..<300).contains(response.statusCode) else {
            throw ProviderError.http(response.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        let planName = await fetchPlanName(token: token)
        return try mapCredits(data, planName: planName)
    }

    /// Settings field `subscription_tier_display` → e.g. "SuperGrok" (like Cursor "Pro").
    private func fetchPlanName(token: String) async -> String? {
        do {
            let (data, response) = try await http.get(
                url: settingsURL,
                headers: authHeaders(token: token)
            )
            guard (200..<300).contains(response.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tier = json["subscription_tier_display"] as? String
            else { return nil }
            let trimmed = tier.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            return nil
        }
    }

    private func authHeaders(token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "X-XAI-Token-Auth": tokenAuthHeader,
            "Accept": "application/json",
            "User-Agent": "Cuprim/0.1"
        ]
    }

    // MARK: - Mapping

    private struct CreditsResponse: Decodable {
        var config: Config?

        struct Config: Decodable {
            var currentPeriod: Period?
            var creditUsagePercent: Double?
            var onDemandCap: Money?
            var onDemandUsed: Money?
            var productUsage: [ProductUsage]?
            var isUnifiedBillingUser: Bool?
            var billingPeriodStart: String?
            var billingPeriodEnd: String?

            struct Period: Decodable {
                var type: String?
                var start: String?
                var end: String?
            }

            struct Money: Decodable {
                var val: Double?
            }

            struct ProductUsage: Decodable {
                var product: String?
                var usagePercent: Double?
            }
        }
    }

    private func mapCredits(_ data: Data, planName: String?) throws -> ProviderSnapshot {
        let decoded = try JSONDecoder().decode(CreditsResponse.self, from: data)
        guard let config = decoded.config else {
            throw ProviderError.decode("missing billing config")
        }

        var metrics: [Metric] = []
        let periodEnd = parseISO(config.billingPeriodEnd)
            ?? parseISO(config.currentPeriod?.end)

        // Grok Build only exposes a shared weekly pool — one meter only.
        if let weekly = config.creditUsagePercent {
            // creditUsagePercent is a whole-percent field (1 = 1%).
            let fraction = Utilization.fraction(fromPercent: weekly)
            metrics.append(
                Metric(
                    id: "weekly",
                    label: "Weekly limit",
                    usedFraction: fraction,
                    resetsAt: periodEnd,
                    detail: "\(Utilization.usedPercent(usedFraction: fraction))% used",
                    showsResetRow: true
                )
            )
        }

        // Prefer SuperGrok / tier from settings; fall back only if unknown.
        let plan = planName ?? (config.isUnifiedBillingUser == true ? "SuperGrok" : nil)

        return ProviderSnapshot(
            id: .grok,
            planName: plan,
            metrics: metrics,
            status: metrics.isEmpty ? .error("No weekly limit data") : .ok,
            fetchedAt: .now
        )
    }

    // MARK: - Auth

    private struct LoadedAuth {
        var accessToken: String
        var refreshToken: String?
        var clientID: String
        var entryKey: String
        var email: String?
        var expiresAt: Date?
        var rawFile: [String: Any]
    }

    private func authPath() -> String {
        let home = ProcessInfo.processInfo.environment["GROK_HOME"]
            ?? NSString(string: "~/.grok").expandingTildeInPath
        return (home as NSString).appendingPathComponent("auth.json")
    }

    private func loadAuth() -> LoadedAuth? {
        let path = authPath()
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        // Prefer auth.x.ai entries; otherwise first token-bearing entry.
        let sortedKeys = root.keys.sorted { a, b in
            let aScore = a.contains("auth.x.ai") ? 0 : 1
            let bScore = b.contains("auth.x.ai") ? 0 : 1
            return aScore < bScore
        }

        for key in sortedKeys {
            guard let entry = root[key] as? [String: Any],
                  let token = entry["key"] as? String,
                  !token.isEmpty
            else { continue }

            let clientID = (entry["oidc_client_id"] as? String)
                ?? key.split(separator: "::").last.map(String.init)
                ?? defaultClientID

            return LoadedAuth(
                accessToken: token,
                refreshToken: entry["refresh_token"] as? String,
                clientID: clientID,
                entryKey: key,
                email: entry["email"] as? String,
                expiresAt: parseISO(entry["expires_at"] as? String),
                rawFile: root
            )
        }
        return nil
    }

    private func needsRefresh(_ auth: LoadedAuth) -> Bool {
        if let expires = auth.expiresAt {
            return expires.timeIntervalSinceNow <= 5 * 60
        }
        // Fall back to JWT exp if present.
        if let exp = jwtExp(auth.accessToken) {
            return exp.timeIntervalSinceNow <= 5 * 60
        }
        return false
    }

    private func jwtExp(_ token: String) -> Date? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload.append("=") }
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? Double
        else { return nil }
        return Date(timeIntervalSince1970: exp)
    }

    private struct RefreshResponse: Decodable {
        var accessToken: String?
        var refreshToken: String?
        var expiresIn: Double?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }

    private func refreshAccessToken(_ auth: LoadedAuth) async throws -> LoadedAuth {
        guard let refresh = auth.refreshToken, !refresh.isEmpty else {
            throw ProviderError.notLoggedIn
        }
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: auth.clientID),
            URLQueryItem(name: "refresh_token", value: refresh)
        ]
        let body = components.percentEncodedQuery?.data(using: .utf8)
        let (data, response) = try await http.post(
            url: refreshURL,
            headers: ["Content-Type": "application/x-www-form-urlencoded", "User-Agent": "Cuprim/0.1"],
            body: body
        )
        guard (200..<300).contains(response.statusCode) else {
            throw ProviderError.http(response.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        guard let access = decoded.accessToken, !access.isEmpty else {
            throw ProviderError.decode("missing access_token")
        }

        var updated = auth
        updated.accessToken = access
        if let newRefresh = decoded.refreshToken { updated.refreshToken = newRefresh }
        if let expiresIn = decoded.expiresIn {
            updated.expiresAt = Date().addingTimeInterval(expiresIn)
        }
        return updated
    }

    private func persist(_ auth: LoadedAuth) {
        var root = auth.rawFile
        var entry = root[auth.entryKey] as? [String: Any] ?? [:]
        entry["key"] = auth.accessToken
        if let refresh = auth.refreshToken {
            entry["refresh_token"] = refresh
        }
        if let expires = auth.expiresAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            entry["expires_at"] = formatter.string(from: expires)
        }
        root[auth.entryKey] = entry
        guard JSONSerialization.isValidJSONObject(root),
              let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        else { return }
        try? data.write(to: URL(fileURLWithPath: authPath()), options: .atomic)
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
