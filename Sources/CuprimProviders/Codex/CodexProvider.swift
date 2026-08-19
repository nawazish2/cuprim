import Foundation
import CuprimCore

public struct CodexProvider: ProviderRuntime {
    public let id: ProviderID = .codex
    var http: HTTPClient

    private let usageURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    public init(http: HTTPClient = HTTPClient()) {
        self.http = http
    }

    public func refresh() async throws -> ProviderSnapshot {
        guard let auth = loadAuth() else {
            throw ProviderError.signedOut
        }
        if isExpired(auth) {
            throw ProviderError.sessionExpired
        }

        let (data, response) = try await http.get(
            url: usageURL,
            headers: [
                "Authorization": "Bearer \(auth.accessToken)",
                "ChatGPT-Account-Id": auth.accountID ?? "",
                "User-Agent": "Cuprim/0.1"
            ]
        )

        try HTTPResponseMapping.throwIfFailed(
            response,
            credentialsPresent: true,
            sessionKnownExpired: isExpired(auth)
        )
        return try CodexUsageMapping.snapshot(fromJSON: data)
    }

    private struct AuthTokens: Decodable {
        var accessToken: String
        var accountId: String?
        var refreshToken: String?
        var expiresAt: Double?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case accountId = "account_id"
            case refreshToken = "refresh_token"
            case expiresAt = "expires_at"
        }
    }

    private struct AuthFile: Decodable {
        var tokens: AuthTokens?
    }

    private struct LoadedAuth {
        var accessToken: String
        var accountID: String?
        var expiresAt: Double?
    }

    private func isExpired(_ auth: LoadedAuth) -> Bool {
        guard let date = ISO8601Parsing.expiryDate(fromUnix: auth.expiresAt) else { return false }
        return date.timeIntervalSinceNow <= 0
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
        return LoadedAuth(
            accessToken: tokens.accessToken,
            accountID: tokens.accountId,
            expiresAt: tokens.expiresAt
        )
    }
}
