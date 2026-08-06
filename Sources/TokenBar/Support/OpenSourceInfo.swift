import AppKit
import Foundation

/// Public project links and credits for the free open-source build.
enum OpenSourceInfo {
    static let displayName = "Open Source · MIT"
    /// Shown in About — matches GitHub handle style (OpenUsage-style credit).
    static let authorName = "nawazish"
    static let authorURL = URL(string: "https://github.com/nawazish2")!
    static let repositoryURL = URL(string: "https://github.com/nawazish2/tokenbar")!
    static let releasesURL = URL(string: "https://github.com/nawazish2/tokenbar/releases")!
    /// Optional tip jar. Leave `nil` until you enable Sponsors / Polar tips.
    static let sponsorsURL: URL? = nil

    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "0.1.3"
        let b = info?["CFBundleVersion"] as? String ?? "4"
        return "Version \(v) (\(b))"
    }

    /// Lightweight updates path — opens GitHub Releases (no Sparkle).
    @MainActor
    static func openReleases() {
        NSWorkspace.shared.open(releasesURL)
    }
}
