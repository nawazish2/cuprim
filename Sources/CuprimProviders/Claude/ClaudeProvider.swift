import Foundation
import Security
import CuprimCore

public struct ClaudeProvider: ProviderRuntime {
    public let id: ProviderID = .claude
    var http: HTTPClient

    private let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    public init(http: HTTPClient = HTTPClient()) {
        self.http = http
    }

    public func hasLocalCredentials() async -> Bool {
        loadOAuth() != nil || loadDesktopUsageSample() != nil
    }

    public func refresh() async throws -> ProviderSnapshot {
        if let oauth = loadOAuth() {
            if isExpired(oauth) {
                if let desktop = loadDesktopUsageSample() {
                    return ClaudeUsageMapping.snapshot(fromDesktop: desktop)
                }
                throw ProviderError.sessionExpired
            }
            if let accessToken = oauth.accessToken, !accessToken.isEmpty {
                do {
                    return try await fetchLiveUsage(accessToken: accessToken, oauth: oauth)
                } catch ProviderError.signedOut, ProviderError.sessionExpired {
                    if let desktop = loadDesktopUsageSample() {
                        return ClaudeUsageMapping.snapshot(fromDesktop: desktop)
                    }
                    throw ProviderError.sessionExpired
                } catch {
                    if let desktop = loadDesktopUsageSample() {
                        return ClaudeUsageMapping.snapshot(fromDesktop: desktop)
                    }
                    throw error
                }
            }
        }

        if let desktop = loadDesktopUsageSample() {
            return ClaudeUsageMapping.snapshot(fromDesktop: desktop)
        }

        throw ProviderError.signedOut
    }

    private func fetchLiveUsage(accessToken: String, oauth: ClaudeOAuth) async throws -> ProviderSnapshot {
        let (data, response) = try await http.get(
            url: usageURL,
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "Cuprim/0.1"
            ]
        )

        if response.statusCode == 429, let desktop = loadDesktopUsageSample() {
            return ClaudeUsageMapping.snapshot(fromDesktop: desktop)
        }

        try HTTPResponseMapping.throwIfFailed(
            response,
            credentialsPresent: true,
            sessionKnownExpired: isExpired(oauth)
        )
        return try ClaudeUsageMapping.snapshot(fromLiveJSON: data, subscriptionHint: oauth.subscriptionType)
    }

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

    private func isExpired(_ oauth: ClaudeOAuth) -> Bool {
        guard let date = ISO8601Parsing.expiryDate(fromUnix: oauth.expiresAt) else { return false }
        return date.timeIntervalSinceNow <= 0
    }

    private func loadOAuth() -> ClaudeOAuth? {
        if let keychain = loadKeychainCredentials() { return keychain }
        if let file = loadFileCredentials() { return file }
        if let env = ProcessInfo.processInfo.environment["CLAUDE_CODE_OAUTH_TOKEN"], !env.isEmpty {
            return ClaudeOAuth(accessToken: env, refreshToken: nil, expiresAt: nil, subscriptionType: nil, scopes: nil)
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
        let services = ["Claude Code-credentials", "Claude Code"]
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

    private func loadDesktopUsageSample() -> ClaudeUsageMapping.DesktopSample? {
        let path = NSString(
            string: "~/Library/Application Support/Claude/plan-usage-history.json"
        ).expandingTildeInPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return ClaudeUsageMapping.desktopSample(fromHistoryJSON: data)
    }
}
