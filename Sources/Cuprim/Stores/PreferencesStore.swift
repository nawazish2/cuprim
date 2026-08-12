import Foundation
import ServiceManagement
import CuprimCore

enum LaunchAtLoginState {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

@MainActor
@Observable
final class PreferencesStore {
    var claudeEnabled: Bool {
        didSet { UserDefaults.standard.set(claudeEnabled, forKey: Keys.claude) }
    }

    var codexEnabled: Bool {
        didSet { UserDefaults.standard.set(codexEnabled, forKey: Keys.codex) }
    }

    var cursorEnabled: Bool {
        didSet { UserDefaults.standard.set(cursorEnabled, forKey: Keys.cursor) }
    }

    var grokEnabled: Bool {
        didSet { UserDefaults.standard.set(grokEnabled, forKey: Keys.grok) }
    }

    /// Auto-refresh interval in minutes (wired to UsageStore loop).
    var refreshMinutes: Int {
        didSet { UserDefaults.standard.set(max(1, refreshMinutes), forKey: Keys.refreshMinutes) }
    }

    /// Show used % as the primary meter value (click toggles remaining).
    var showUsedPercent: Bool {
        didSet { UserDefaults.standard.set(showUsedPercent, forKey: Keys.showUsedPercent) }
    }

    /// CodexBar-style absolute reset times ("Resets 1 Sep at 5:30 AM").
    var absoluteResetTimes: Bool {
        didSet { UserDefaults.standard.set(absoluteResetTimes, forKey: Keys.absoluteResets) }
    }

    /// Hide providers that are not logged in (less noise, CodexBar-like focus).
    var hideLoggedOutProviders: Bool {
        didSet { UserDefaults.standard.set(hideLoggedOutProviders, forKey: Keys.hideLoggedOut) }
    }

    /// Opt-in local notifications from Quota Horizon.
    var horizonAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(horizonAlertsEnabled, forKey: Keys.horizonAlerts) }
    }

    /// Display order for providers (tabs + All list). Drag to reorder with the cursor.
    var providerOrder: [ProviderID] {
        didSet {
            let raw = providerOrder.map(\.rawValue)
            UserDefaults.standard.set(raw, forKey: Keys.providerOrder)
        }
    }

    private(set) var launchAtLoginState: LaunchAtLoginState
    private(set) var launchAtLoginError: String?

    init() {
        let defaults = UserDefaults.standard
        claudeEnabled = defaults.object(forKey: Keys.claude) as? Bool ?? true
        codexEnabled = defaults.object(forKey: Keys.codex) as? Bool ?? true
        cursorEnabled = defaults.object(forKey: Keys.cursor) as? Bool ?? true
        grokEnabled = defaults.object(forKey: Keys.grok) as? Bool ?? true

        if defaults.object(forKey: Keys.refreshMigratedTo2) == nil {
            refreshMinutes = 2
            defaults.set(2, forKey: Keys.refreshMinutes)
            defaults.set(true, forKey: Keys.refreshMigratedTo2)
        } else {
            let minutes = defaults.integer(forKey: Keys.refreshMinutes)
            refreshMinutes = minutes > 0 ? minutes : 2
        }

        showUsedPercent = defaults.object(forKey: Keys.showUsedPercent) as? Bool ?? true
        absoluteResetTimes = defaults.object(forKey: Keys.absoluteResets) as? Bool ?? true
        hideLoggedOutProviders = defaults.object(forKey: Keys.hideLoggedOut) as? Bool ?? true
        horizonAlertsEnabled = defaults.object(forKey: Keys.horizonAlerts) as? Bool ?? false

        if let saved = defaults.stringArray(forKey: Keys.providerOrder) {
            var order = saved.compactMap(ProviderID.init(rawValue:))
            // Append any new providers not in saved order.
            for id in ProviderID.allCases where !order.contains(id) {
                order.append(id)
            }
            providerOrder = order.isEmpty ? Array(ProviderID.allCases) : order
        } else {
            providerOrder = Array(ProviderID.allCases)
        }

        launchAtLoginState = Self.currentLaunchAtLoginState()
        launchAtLoginError = nil
    }

    func isEnabled(_ id: ProviderID) -> Bool {
        switch id {
        case .claude: claudeEnabled
        case .codex: codexEnabled
        case .cursor: cursorEnabled
        case .grok: grokEnabled
        }
    }

    func setEnabled(_ id: ProviderID, _ enabled: Bool) {
        switch id {
        case .claude: claudeEnabled = enabled
        case .codex: codexEnabled = enabled
        case .cursor: cursorEnabled = enabled
        case .grok: grokEnabled = enabled
        }
    }

    /// Providers in the user’s preferred order.
    var orderedProviders: [ProviderID] {
        let known = Set(ProviderID.allCases)
        var seen = Set<ProviderID>()
        var result: [ProviderID] = []
        for id in providerOrder where known.contains(id) && !seen.contains(id) {
            result.append(id)
            seen.insert(id)
        }
        for id in ProviderID.allCases where !seen.contains(id) {
            result.append(id)
        }
        return result
    }

    func moveProviders(from source: IndexSet, to destination: Int) {
        var order = orderedProviders
        order.move(fromOffsets: source, toOffset: destination)
        providerOrder = order
    }

    func moveProvider(_ id: ProviderID, direction: Int) {
        var order = orderedProviders
        guard let index = order.firstIndex(of: id) else { return }
        let newIndex = index + direction
        guard order.indices.contains(newIndex) else { return }
        order.swapAt(index, newIndex)
        providerOrder = order
    }

    var launchAtLogin: Bool {
        get {
            launchAtLoginState == .enabled || launchAtLoginState == .requiresApproval
        }
        set {
            setLaunchAtLogin(newValue)
        }
    }

    func refreshLaunchAtLoginState() {
        launchAtLoginState = Self.currentLaunchAtLoginState()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginError = error.localizedDescription
        }
        refreshLaunchAtLoginState()
    }

    private static func currentLaunchAtLoginState() -> LaunchAtLoginState {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    private enum Keys {
        static let claude = "provider.claude.enabled"
        static let codex = "provider.codex.enabled"
        static let cursor = "provider.cursor.enabled"
        static let grok = "provider.grok.enabled"
        static let refreshMinutes = "refresh.minutes"
        static let refreshMigratedTo2 = "refresh.migratedTo2min"
        static let showUsedPercent = "display.showUsedPercent"
        static let absoluteResets = "display.absoluteResets"
        static let hideLoggedOut = "display.hideLoggedOut"
        static let horizonAlerts = "horizon.alertsEnabled"
        static let providerOrder = "provider.order"
    }
}
