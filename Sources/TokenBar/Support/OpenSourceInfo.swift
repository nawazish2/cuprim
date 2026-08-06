import Foundation

/// Public project links and credits for the free open-source build.
enum OpenSourceInfo {
    static let displayName = "Open Source · MIT"
    static let authorName = "Nawazish Khan"
    static let authorURL = URL(string: "https://github.com/nawazish2")!
    static let repositoryURL = URL(string: "https://github.com/nawazish2/tokenbar")!
    static let releasesURL = URL(string: "https://github.com/nawazish2/tokenbar/releases")!
    /// Optional tip jar. Leave `nil` until you enable Sponsors / Polar tips.
    static let sponsorsURL: URL? = nil

    static var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.2"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "3"
        return "Version \(v) (\(b))"
    }
}
