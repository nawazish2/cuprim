import AppKit
import Foundation
import CuprimCore

enum ProviderLoginAction {
    case copyCommand(String)
    case openApp(bundleIdentifier: String)
    case refresh

    var title: String {
        switch self {
        case .copyCommand(let command):
            return "Copy \(command)"
        case .openApp:
            return "Open app"
        case .refresh:
            return "Refresh"
        }
    }

    static func primary(for id: ProviderID) -> ProviderLoginAction {
        switch id {
        case .claude:
            return .copyCommand("claude")
        case .codex:
            return .copyCommand("codex login")
        case .cursor:
            return .openApp(bundleIdentifier: "com.todesktop.230313mzl4w4u92")
        case .grok:
            return .copyCommand("grok login")
        case .antigravity:
            return .copyCommand("agy")
        }
    }

    static func hint(for id: ProviderID) -> String {
        switch id {
        case .claude: return "Sign in to Claude Desktop or run claude in Terminal."
        case .codex: return "Sign in with the Codex CLI."
        case .cursor: return "Open Cursor and sign in."
        case .grok: return "Sign in with Grok Build."
        case .antigravity: return "Open Antigravity or run agy."
        }
    }

    func perform() {
        switch self {
        case .copyCommand(let command):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(command, forType: .string)
        case .openApp(let bundleIdentifier):
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } else {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Cursor.app"))
            }
        case .refresh:
            break
        }
    }
}
