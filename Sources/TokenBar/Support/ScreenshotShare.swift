import AppKit
import TokenBarCore

/// Render an OpenUsage-style usage card and share it to an AI app.
enum ScreenshotShare {
    enum Target: String, CaseIterable {
        case claude
        case codex
        case cursor
        case grok

        var title: String {
            switch self {
            case .claude: "Claude"
            case .codex: "Codex"
            case .cursor: "Cursor"
            case .grok: "Grok"
            }
        }

        var bundleIdentifiers: [String] {
            switch self {
            case .claude:
                ["com.anthropic.claudesktop", "com.anthropic.claude", "com.anthropic.claudefordesktop"]
            case .codex:
                ["com.openai.chat", "com.openai.chatgpt"]
            case .cursor:
                ["com.todesktop.230313mzl4w4u92", "com.cursor.Cursor", "dev.cursor.Cursor"]
            case .grok:
                ["ai.x.grok", "com.xai.grok", "ai.xai.grok"]
            }
        }

        var appNameFallbacks: [String] {
            switch self {
            case .claude: ["Claude", "Claude.app"]
            case .codex: ["ChatGPT", "ChatGPT.app", "Codex"]
            case .cursor: ["Cursor", "Cursor.app"]
            case .grok: ["Grok", "Grok.app"]
            }
        }
    }

    @MainActor
    static func share(image: NSImage, summary: String, to target: Target) {
        copyToPasteboard(image: image, summary: summary)
        activate(target)
    }

    @MainActor
    static func copyToPasteboard(image: NSImage, summary: String) {
        let pb = NSPasteboard.general
        pb.clearContents()

        // Prefer PNG so chat apps paste a crisp bitmap instead of a soft preview.
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            pb.setData(png, forType: .png)
            pb.setData(tiff, forType: .tiff)
        } else {
            pb.writeObjects([image])
        }

        if !summary.isEmpty {
            pb.setString(summary, forType: .string)
        }
    }

    @MainActor
    private static func activate(_ target: Target) {
        let workspace = NSWorkspace.shared
        for id in target.bundleIdentifiers {
            if let url = workspace.urlForApplication(withBundleIdentifier: id) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                workspace.openApplication(at: url, configuration: config)
                return
            }
        }
        for name in target.appNameFallbacks {
            let candidates = [
                "/Applications/\(name.replacingOccurrences(of: ".app", with: "")).app",
                "\(NSHomeDirectory())/Applications/\(name.replacingOccurrences(of: ".app", with: "")).app"
            ]
            for path in candidates where FileManager.default.fileExists(atPath: path) {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                workspace.openApplication(at: URL(fileURLWithPath: path), configuration: config)
                return
            }
        }
        // Still useful — screenshot is on the clipboard for Cmd+V.
        NSSound.beep()
    }

    static func usageSummary(from snapshots: [ProviderSnapshot], showUsed: Bool) -> String {
        var lines = ["TokenBar usage snapshot"]
        for snap in snapshots {
            let plan = snap.planName.map { " (\($0))" } ?? ""
            switch snap.status {
            case .notLoggedIn:
                lines.append("• \(snap.id.displayName)\(plan): not signed in")
            case .error(let message):
                lines.append("• \(snap.id.displayName)\(plan): \(message)")
            case .ok:
                let parts = snap.metrics.compactMap { metric -> String? in
                    guard let fraction = metric.usedFraction else { return metric.detail }
                    let value = showUsed
                        ? QuotaFormatting.usedPercentLabel(usedFraction: fraction) + " used"
                        : QuotaFormatting.remainingLabel(usedFraction: fraction) + " left"
                    return "\(metric.label) \(value)"
                }
                let detail = parts.isEmpty ? "ok" : parts.joined(separator: " · ")
                lines.append("• \(snap.id.displayName)\(plan): \(detail)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

extension NSView {
    @MainActor
    func tokenBarSnapshotImage() -> NSImage? {
        let size = bounds.size
        guard size.width > 1, size.height > 1 else { return nil }
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }
}
