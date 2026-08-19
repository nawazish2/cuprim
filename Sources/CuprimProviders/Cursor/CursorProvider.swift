import Foundation
import CuprimCore

public struct CursorProvider: ProviderRuntime {
    public let id: ProviderID = .cursor
    var http: HTTPClient

    private let usageSummaryURL = URL(string: "https://cursor.com/api/usage-summary")!
    private let stripeURL = URL(string: "https://api2.cursor.sh/auth/full_stripe_profile")!

    public init(http: HTTPClient = HTTPClient()) {
        self.http = http
    }

    public func refresh() async throws -> ProviderSnapshot {
        let token: String
        do {
            guard let loaded = try loadAccessToken() else {
                throw ProviderError.signedOut
            }
            token = loaded
        } catch let error as ProviderError {
            throw error
        }

        let cookie = "WorkosCursorSessionToken=::\(token)"
        let (data, response) = try await http.get(
            url: usageSummaryURL,
            headers: [
                "Cookie": cookie,
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_0; arm64) Cuprim/0.1"
            ]
        )

        try HTTPResponseMapping.throwIfFailed(response, credentialsPresent: true)
        var snapshot = try CursorUsageMapping.snapshot(fromJSON: data)
        if let plan = try? await fetchPlanName(token: token) {
            snapshot.planName = plan
        }
        return snapshot
    }

    private func loadAccessToken() throws -> String? {
        let path = NSString(
            string: "~/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
        ).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return try SQLiteReader.string(
            path: path,
            sql: "SELECT value FROM ItemTable WHERE key = ? LIMIT 1;",
            bind: "cursorAuth/accessToken"
        )
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
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_0; arm64) Cuprim/0.1"
            ]
        )
        guard (200..<300).contains(response.statusCode) else { return nil }
        let profile = try JSONDecoder().decode(StripeProfile.self, from: data)
        return (profile.individualMembershipType ?? profile.membershipType)?.capitalized
    }
}
