import AppKit
import Foundation
import TokenBarCore

/// Resource loading that works in a packaged `.app` (never uses SPM `Bundle.module`,
/// which crashes when the resource bundle path doesn't match).
enum AppResources {
    /// Bundles to search: main app, then SPM bundle next to the executable if present.
    static var searchBundles: [Bundle] {
        var list: [Bundle] = [.main]
        if let exeDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            let sibling = exeDir.appendingPathComponent("TokenBar_TokenBar.bundle")
            if let b = Bundle(url: sibling) {
                list.append(b)
            }
            // Nested Contents/Resources of that bundle
            let nested = sibling.appendingPathComponent("Contents/Resources")
            if FileManager.default.fileExists(atPath: nested.path) {
                // Prefer files via main + absolute paths below
            }
        }
        return list
    }

    static func url(name: String, ext: String, subdirectory: String? = nil) -> URL? {
        for bundle in searchBundles {
            if let sub = subdirectory,
               let url = bundle.url(forResource: name, withExtension: ext, subdirectory: sub) {
                return url
            }
            if let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
            // SPM flattens: MenuBar/Icon.png → MenuBarIcon.png sometimes; try path in Resources
            if let res = bundle.resourceURL {
                var candidates: [URL] = []
                if let sub = subdirectory {
                    candidates.append(res.appendingPathComponent(sub).appendingPathComponent("\(name).\(ext)"))
                }
                candidates.append(res.appendingPathComponent("\(name).\(ext)"))
                candidates.append(res.appendingPathComponent("\(subdirectory ?? "")/\(name).\(ext)"))
                for c in candidates where FileManager.default.fileExists(atPath: c.path) {
                    return c
                }
            }
        }

        // Absolute fallbacks next to executable / app Resources
        if let exeDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            let paths = [
                exeDir.appendingPathComponent("TokenBar_TokenBar.bundle/Contents/Resources/\(name).\(ext)"),
                exeDir.appendingPathComponent("../Resources/\(subdirectory ?? "")/\(name).\(ext)"),
                exeDir.appendingPathComponent("../Resources/\(name).\(ext)"),
                exeDir.appendingPathComponent("../Resources/MenuBar/\(name).\(ext)"),
                exeDir.appendingPathComponent("../Resources/ProviderIcons/\(name).\(ext)"),
            ]
            for p in paths {
                let standardized = p.standardizedFileURL
                if FileManager.default.fileExists(atPath: standardized.path) {
                    return standardized
                }
            }
        }
        return nil
    }

    static func image(name: String, subdirectory: String? = nil) -> NSImage? {
        // Prefer @2x on retina
        let scale = NSScreen.main?.backingScaleFactor ?? 2
        if scale >= 2, let url = url(name: "\(name)@2x", ext: "png", subdirectory: subdirectory),
           let image = NSImage(contentsOf: url) {
            return image
        }
        if let url = url(name: name, ext: "png", subdirectory: subdirectory),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }
}
