import AppKit
import Foundation

/// Manual release checker for the free, non-notarized GitHub distribution.
///
/// Cuprim intentionally never downloads, unpacks, or replaces its own app.
/// Users review and install releases from GitHub, preserving Gatekeeper's
/// normal first-open flow and avoiding an unverifiable self-update path.
@MainActor
enum AppUpdater {
    private static var isChecking = false

    static func checkForUpdates(interactive: Bool = true) {
        guard !isChecking else { return }
        isChecking = true

        Task {
            defer { isChecking = false }
            do {
                let latest = try await fetchLatestRelease()
                let current = currentMarketingVersion()
                if compareVersions(latest.marketingVersion, current) <= 0 {
                    if interactive {
                        present(
                            title: "You’re up to date",
                            message: "Cuprim \(current) is the current version."
                        )
                    }
                    return
                }

                guard interactive else { return }
                let alert = NSAlert()
                alert.messageText = "Cuprim \(latest.marketingVersion) is available"
                var message = "You have \(current). Download the release from GitHub when you’re ready."
                if let notes = latest.body?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                    let short = notes.count > 280 ? String(notes.prefix(280)) + "…" : notes
                    message += "\n\n" + short
                }
                alert.informativeText = message
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open GitHub Releases")
                alert.addButton(withTitle: "Later")
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(latest.htmlURL ?? OpenSourceInfo.releasesURL)
                }
            } catch {
                if interactive {
                    present(
                        title: "Couldn’t check for updates",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private struct ReleaseDTO: Decodable {
        let tagName: String
        let body: String?
        let htmlURL: URL?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case body
            case htmlURL = "html_url"
        }

        var marketingVersion: String {
            tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        }
    }

    private static func fetchLatestRelease() async throws -> ReleaseDTO {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/nawazish2/cuprim/releases/latest")!)
        request.setValue("Cuprim", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw UpdateError.http(http.statusCode)
        }
        return try JSONDecoder().decode(ReleaseDTO.self, from: data)
    }

    static func currentMarketingVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// -1 if a < b, 0 if equal, 1 if a > b. Missing components are zero.
    static func compareVersions(_ a: String, _ b: String) -> Int {
        let ap = a.split(separator: ".").compactMap { Int($0) }
        let bp = b.split(separator: ".").compactMap { Int($0) }
        for index in 0..<max(ap.count, bp.count) {
            let av = index < ap.count ? ap[index] : 0
            let bv = index < bp.count ? bp[index] : 0
            if av < bv { return -1 }
            if av > bv { return 1 }
        }
        return 0
    }

    private static func present(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    enum UpdateError: LocalizedError {
        case http(Int)

        var errorDescription: String? {
            switch self {
            case .http(let code): return "GitHub returned HTTP \(code)."
            }
        }
    }
}
