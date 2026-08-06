import Foundation

/// Public project links for the free open-source build.
enum OpenSourceInfo {
    static let displayName = "Open Source · MIT"
    static let repositoryURL = URL(string: "https://github.com/nawazish2/tokenbar")!
    static let releasesURL = URL(string: "https://github.com/nawazish2/tokenbar/releases")!
    /// Optional tip jar. Leave `nil` until you enable Sponsors / Polar tips.
    static let sponsorsURL: URL? = nil
}
