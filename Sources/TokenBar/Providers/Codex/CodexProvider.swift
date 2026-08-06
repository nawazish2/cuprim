import Foundation
import TokenBarCore

struct CodexProvider: ProviderRuntime {
    let id: ProviderID = .codex
    var http = HTTPClient()

    private let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    func hasLocalCredentials() async -> Bool {
        loadAuth() != nil
    }

    func refresh() async throws -> ProviderSnapshot {
        guard let auth = loadAuth() else {
            return .empty(.codex, status: .notLoggedIn)
        }

        let (data, response) = try await http.get(
            url: usageURL,
            headers: [
                "Authorization": "Bearer \(auth.accessToken)",
                "ChatGPT-Account-Id": auth.accountID ?? "",
                "User-Agent": "TokenBar/0.1"
            ]
        )

        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 || response.statusCode == 403 {
                return .empty(.codex, status: .notLoggedIn)
            }
            throw ProviderError.http(response.statusCode, String(data: data, encoding: .utf8) ?? "")
        }

        return try mapUsage(data)
    }

    // MARK: - Auth

    private struct AuthTokens: Decodable {
        var accessToken: String
        var accountId: String?
        var refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case accountId = "account_id"
            case refreshToken = "refresh_token"
        }
    }

    private struct AuthFile: Decodable {
        var tokens: AuthTokens?
    }

    private struct LoadedAuth {
        var accessToken: String
        var accountID: String?
    }

    private func loadAuth() -> LoadedAuth? {
        let home = ProcessInfo.processInfo.environment["CODEX_HOME"]
            ?? NSString(string: "~/.codex").expandingTildeInPath
        let path = (home as NSString).appendingPathComponent("auth.json")
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let file = try? JSONDecoder().decode(AuthFile.self, from: data),
              let tokens = file.tokens,
              !tokens.accessToken.isEmpty
        else { return nil }
        return LoadedAuth(accessToken: tokens.accessToken, accountID: tokens.accountId)
    }

    // MARK: - Mapping

    private struct UsageResponse: Decodable {
        var planType: String?
        var rateLimit: RateLimit?

        enum CodingKeys: String, CodingKey {
            case planType = "plan_type"
            case rateLimit = "rate_limit"
        }

        struct RateLimit: Decodable {
            var primaryWindow: Window?
            var secondaryWindow: Window?

            enum CodingKeys: String, CodingKey {
                case primaryWindow = "primary_window"
                case secondaryWindow = "secondary_window"
            }
        }

        struct Window: Decodable {
            var usedPercent: Double?
            var limitWindowSeconds: Double?
            var resetAfterSeconds: Double?
            var resetAt: Double?

            enum CodingKeys: String, CodingKey {
                case usedPercent = "used_percent"
                case limitWindowSeconds = "limit_window_seconds"
                case resetAfterSeconds = "reset_after_seconds"
                case resetAt = "reset_at"
            }
        }
    }

    private func mapUsage(_ data: Data) throws -> ProviderSnapshot {
        let decoded = try JSONDecoder().decode(UsageResponse.self, from: data)
        var windows: [(String, String, UsageResponse.Window)] = []

        if let primary = decoded.rateLimit?.primaryWindow {
            windows.append(classify(primary))
        }
        if let secondary = decoded.rateLimit?.secondaryWindow {
            windows.append(classify(secondary))
        }

        // Deduplicate ids if classification collides.
        var seen = Set<String>()
        var metrics: [Metric] = []
        for (id, label, window) in windows {
            var metricID = id
            if seen.contains(metricID) {
                metricID = "\(id)-\(metrics.count)"
            }
            seen.insert(metricID)
            metrics.append(metric(id: metricID, label: label, window: window))
        }

        return ProviderSnapshot(
            id: .codex,
            planName: decoded.planType?.capitalized,
            metrics: metrics,
            status: metrics.isEmpty ? .error("No usage data") : .ok,
            fetchedAt: .now
        )
    }

    private func classify(_ window: UsageResponse.Window) -> (String, String, UsageResponse.Window) {
        let seconds = window.limitWindowSeconds ?? 0
        let kind = CodexWindowClassifier.kind(windowSeconds: seconds)
        return (kind.rawValue, CodexWindowClassifier.label(for: kind), window)
    }

    private func metric(id: String, label: String, window: UsageResponse.Window) -> Metric {
        // Codex `used_percent` is always 0…100 (1 = 1%).
        let percent = window.usedPercent ?? 0
        let fraction = Utilization.fraction(fromPercent: percent)
        let resetsAt: Date?
        if let resetAt = window.resetAt {
            // Codex sends epoch seconds.
            resetsAt = Date(timeIntervalSince1970: resetAt)
        } else if let after = window.resetAfterSeconds {
            resetsAt = Date().addingTimeInterval(after)
        } else {
            resetsAt = nil
        }
        let usedPct = Utilization.usedPercent(usedFraction: fraction)
        return Metric(
            id: id,
            label: label,
            usedFraction: fraction,
            resetsAt: resetsAt,
            detail: "\(usedPct)% of limit used",
            showsResetRow: true
        )
    }
}
