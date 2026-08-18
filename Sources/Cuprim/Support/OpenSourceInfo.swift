import AppKit
import Foundation

/// Public project links and credits for the free open-source build.
enum OpenSourceInfo {
    static let displayName = "Open Source · MIT"
    static let authorName = "Nawazish"
    static let authorURL = URL(string: "https://github.com/nawazish2")!
    static let repositoryURL = URL(string: "https://github.com/nawazish2/cuprim")!
    static let releasesURL = URL(string: "https://github.com/nawazish2/cuprim/releases")!
    static let sponsorsURL: URL? = nil

    static var versionString: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "0.1.6"
        let b = info?["CFBundleVersion"] as? String ?? "7"
        return "Version \(v) (\(b))"
    }

    @MainActor
    static func checkForUpdates() {
        UpdaterManager.shared.checkForUpdates()
    }

    @MainActor
    static func openReleases() {
        NSWorkspace.shared.open(releasesURL)
    }
}
