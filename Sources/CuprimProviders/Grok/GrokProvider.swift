import Foundation
import CuprimCore

actor GrokCredentialStore {
    private let defaultClientID = "b1a00492-073a-47ea-816f-4c329264a828"

    struct LoadedAuth: Sendable {
        var accessToken: String
        var refreshToken: String?
        var clientID: String
        var entryKey: String
        var email: String?
        var expiresAt: Date?
    }

    func load() -> LoadedAuth? {
        let path = authPath()
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return parse(root)
    }

    func persist(_ auth: LoadedAuth) throws {
        let url = URL(fileURLWithPath: authPath())
        let fm = FileManager.default
        var permissions: NSNumber?
        if fm.fileExists(atPath: url.path) {
            permissions = (try? fm.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber)
        }

        var root: [String: Any] = [:]
        if let data = try? Data(contentsOf: url),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = parsed
        }

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

        guard JSONSerialization.isValidJSONObject(root) else {
            throw ProviderError.unavailable
        }
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        let temp = url.appendingPathExtension("tmp")
        try data.write(to: temp, options: .atomic)
        if fm.fileExists(atPath: url.path) {
            _ = try fm.replaceItemAt(url, withItemAt: temp)
        } else {
            try fm.moveItem(at: temp, to: url)
        }
        if let permissions {
            try? fm.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
        } else {
            try? fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        }
    }

    private func parse(_ root: [String: Any]) -> LoadedAuth? {
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
                expiresAt: ISO8601Parsing.date(from: entry["expires_at"] as? String)
            )
        }
        return nil
    }

    private func authPath() -> String {
        let home = ProcessInfo.processInfo.environment["GROK_HOME"]
            ?? NSString(string: "~/.grok").expandingTildeInPath
        return (home as NSString).appendingPathComponent("auth.json")
    }
}

public struct GrokProvider: ProviderRuntime {
    public let id: ProviderID = .grok
    var http: HTTPClient
    private let credentials = GrokCredentialStore()

    private let creditsURL = URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits")!
    private let settingsURL = URL(string: "https://cli-chat-proxy.grok.com/v1/settings")!
    private let refreshURL = URL(string: "https://auth.x.ai/oauth2/token")!
    private let tokenAuthHeader = "xai-grok-cli"

    public init(http: HTTPClient = HTTPClient()) {
        self.http = http
    }

    public func hasLocalCredentials() async -> Bool {
        await credentials.load() != nil
    }

    public func refresh() async throws -> ProviderSnapshot {
        guard var auth = await credentials.load() else {
            throw ProviderError.signedOut
        }

        if needsRefresh(auth), let refreshed = try? await refreshAccessToken(auth) {
            auth = refreshed
            try? await credentials.persist(auth)
        }

        do {
            return try await fetchCredits(auth: auth)
        } catch {
            let shouldRetry: Bool
            if let provider = error as? ProviderError {
                switch provider {
                case .signedOut, .sessionExpired, .http:
                    shouldRetry = true
                default:
                    shouldRetry = false
                }
            } else {
                shouldRetry = false
            }
            guard shouldRetry, let refreshed = try? await refreshAccessToken(auth) else {
                if error is ProviderError { throw error }
                throw error
            }
            try? await credentials.persist(refreshed)
            return try await fetchCredits(auth: refreshed)
        }
    }

    private func fetchCredits(auth: GrokCredentialStore.LoadedAuth) async throws -> ProviderSnapshot {
        let (data, response) = try await http.get(
            url: creditsURL,
            headers: authHeaders(token: auth.accessToken)
        )
        try HTTPResponseMapping.throwIfFailed(response, credentialsPresent: true)
        let planName = await fetchPlanName(token: auth.accessToken)
        return try GrokUsageMapping.snapshot(fromJSON: data, planName: planName)
    }

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

    private func needsRefresh(_ auth: GrokCredentialStore.LoadedAuth) -> Bool {
        if let expires = auth.expiresAt {
            return expires.timeIntervalSinceNow <= 5 * 60
        }
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

    private func refreshAccessToken(_ auth: GrokCredentialStore.LoadedAuth) async throws -> GrokCredentialStore.LoadedAuth {
        guard let refresh = auth.refreshToken, !refresh.isEmpty else {
            throw ProviderError.sessionExpired
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
        try HTTPResponseMapping.throwIfFailed(response, credentialsPresent: true)
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        guard let access = decoded.accessToken, !access.isEmpty else {
            throw ProviderError.decode
        }
        var updated = auth
        updated.accessToken = access
        if let newRefresh = decoded.refreshToken { updated.refreshToken = newRefresh }
        if let expiresIn = decoded.expiresIn {
            updated.expiresAt = Date().addingTimeInterval(expiresIn)
        }
        return updated
    }
}
