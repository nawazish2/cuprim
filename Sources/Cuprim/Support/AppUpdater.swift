import AppKit
import Foundation

/// Checks GitHub Releases and installs newer builds without opening a browser.
@MainActor
enum AppUpdater {
    private static var isChecking = false
    private static var progressPanel: NSWindow?

    static func checkForUpdates(interactive: Bool = true) {
        guard !isChecking else { return }
        isChecking = true

        Task {
            defer { isChecking = false }
            do {
                showProgress("Checking for updates…")
                let latest = try await fetchLatestRelease()
                let current = currentMarketingVersion()
                let remote = latest.marketingVersion
                hideProgress()

                if compareVersions(remote, current) <= 0 {
                    if interactive {
                        present(
                            title: "You’re up to date",
                            message: "Cuprim \(current) is the current version."
                        )
                    }
                    return
                }

                let proceed = confirmUpdate(from: current, to: remote, notes: latest.body)
                guard proceed else { return }

                guard let asset = latest.zipAsset else {
                    present(
                        title: "Update unavailable",
                        message: "No downloadable app zip was found for \(remote)."
                    )
                    return
                }

                showProgress("Downloading Cuprim \(remote)…")
                let zipURL = try await download(asset: asset)

                showProgress("Installing update…")
                try installAndRelaunch(zipURL: zipURL)
            } catch {
                hideProgress()
                if interactive {
                    present(
                        title: "Couldn’t check for updates",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - GitHub

    private struct ReleaseDTO: Decodable {
        var tagName: String
        var body: String?
        var assets: [AssetDTO]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case body
            case assets
        }

        var marketingVersion: String {
            tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        }

        var zipAsset: AssetDTO? {
            assets.first { $0.name.lowercased().hasSuffix(".app.zip") }
                ?? assets.first {
                    $0.name.lowercased().hasSuffix(".zip")
                        && !$0.name.lowercased().contains("source")
                }
        }
    }

    private struct AssetDTO: Decodable {
        var name: String
        var browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    private static func fetchLatestRelease() async throws -> ReleaseDTO {
        let url = URL(string: "https://api.github.com/repos/nawazish2/cuprim/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("Cuprim", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw UpdateError.http(http.statusCode)
        }
        return try JSONDecoder().decode(ReleaseDTO.self, from: data)
    }

    private static func download(asset: AssetDTO) async throws -> URL {
        let (tempURL, response) = try await URLSession.shared.download(from: asset.browserDownloadURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw UpdateError.http(http.statusCode)
        }
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("Cuprim-update-\(UUID().uuidString).zip")
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tempURL, to: dest)
        return dest
    }

    // MARK: - Install

    private static func installAndRelaunch(zipURL: URL) throws {
        let fm = FileManager.default
        let workDir = fm.temporaryDirectory
            .appendingPathComponent("Cuprim-update-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzip.arguments = ["-x", "-k", zipURL.path, workDir.path]
        try unzip.run()
        unzip.waitUntilExit()
        guard unzip.terminationStatus == 0 else {
            throw UpdateError.unzipFailed
        }

        guard let newApp = findAppBundle(in: workDir) else {
            throw UpdateError.appMissing
        }

        let currentApp = Bundle.main.bundleURL
        let scriptURL = workDir.appendingPathComponent("install.sh")
        let script = """
        #!/bin/bash
        set -euo pipefail
        TARGET=\(shellEscape(currentApp.path))
        SOURCE=\(shellEscape(newApp.path))
        WORK=\(shellEscape(workDir.path))
        ZIP=\(shellEscape(zipURL.path))
        while /usr/bin/pgrep -x Cuprim >/dev/null 2>&1; do
          sleep 0.25
        done
        /bin/rm -rf "$TARGET"
        /usr/bin/ditto "$SOURCE" "$TARGET"
        /usr/bin/xattr -cr "$TARGET" >/dev/null 2>&1 || true
        /usr/bin/open "$TARGET"
        /bin/rm -rf "$WORK" "$ZIP"
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let installer = Process()
        installer.executableURL = URL(fileURLWithPath: "/bin/bash")
        installer.arguments = [scriptURL.path]
        installer.standardOutput = FileHandle.nullDevice
        installer.standardError = FileHandle.nullDevice
        try installer.run()

        hideProgress()
        NSApp.terminate(nil)
    }

    private static func findAppBundle(in directory: URL) -> URL? {
        let fm = FileManager.default
        var fallback: URL?
        if let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else { continue }
                if url.lastPathComponent == "Cuprim.app" {
                    return url
                }
                if fallback == nil {
                    fallback = url
                }
            }
        }
        return fallback
    }

    // MARK: - Versioning

    static func currentMarketingVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// -1 if a < b, 0 if equal, 1 if a > b
    static func compareVersions(_ a: String, _ b: String) -> Int {
        let ap = a.split(separator: ".").compactMap { Int($0) }
        let bp = b.split(separator: ".").compactMap { Int($0) }
        let count = max(ap.count, bp.count)
        for i in 0..<count {
            let av = i < ap.count ? ap[i] : 0
            let bv = i < bp.count ? bp[i] : 0
            if av < bv { return -1 }
            if av > bv { return 1 }
        }
        return 0
    }

    // MARK: - UI

    private static func present(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static func confirmUpdate(from current: String, to remote: String, notes: String?) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Update available"
        var text = "Cuprim \(remote) is available (you have \(current)).\n\nDownload and install now?"
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let short = trimmed.count > 280 ? String(trimmed.prefix(280)) + "…" : trimmed
            text += "\n\n" + short
        }
        alert.informativeText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Later")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func showProgress(_ message: String) {
        if progressPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 280, height: 88),
                styleMask: [.titled],
                backing: .buffered,
                defer: false
            )
            panel.title = "Cuprim"
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.center()

            let spinner = NSProgressIndicator(frame: NSRect(x: 20, y: 36, width: 24, height: 24))
            spinner.style = .spinning
            spinner.startAnimation(nil)

            let label = NSTextField(labelWithString: message)
            label.frame = NSRect(x: 52, y: 38, width: 210, height: 20)
            label.font = .systemFont(ofSize: 13)
            label.tag = 100

            panel.contentView?.addSubview(spinner)
            panel.contentView?.addSubview(label)
            panel.orderFrontRegardless()
            progressPanel = panel
        } else if let label = progressPanel?.contentView?.viewWithTag(100) as? NSTextField {
            label.stringValue = message
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func hideProgress() {
        progressPanel?.orderOut(nil)
        progressPanel = nil
    }

    private static func shellEscape(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    enum UpdateError: LocalizedError {
        case http(Int)
        case unzipFailed
        case appMissing

        var errorDescription: String? {
            switch self {
            case .http(let code):
                return "GitHub returned HTTP \(code)."
            case .unzipFailed:
                return "Couldn’t unpack the update archive."
            case .appMissing:
                return "The download didn’t contain Cuprim.app."
            }
        }
    }
}
