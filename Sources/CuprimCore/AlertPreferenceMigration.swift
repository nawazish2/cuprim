import Foundation

/// One-time mapping from the old Quota Horizon preference to low-quota alerts.
public enum AlertPreferenceMigration {
    public static func resolved(current: Bool?, legacy: Bool?) -> Bool {
        if let current { return current }
        if let legacy { return legacy }
        return false
    }
}
