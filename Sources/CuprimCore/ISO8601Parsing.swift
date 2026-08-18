import Foundation

public enum ISO8601Parsing {
    public static func date(from value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) { return date }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

    public static func date(fromAny raw: Any?) -> Date? {
        if let text = raw as? String {
            return date(from: text)
        }
        if let seconds = raw as? Double {
            return Date(timeIntervalSince1970: epochSeconds(seconds))
        }
        if let seconds = raw as? Int {
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }
        return nil
    }

    /// Claude/Codex expiry fields may be seconds or milliseconds.
    public static func expiryDate(fromUnix value: Double?) -> Date? {
        guard let value, value > 0 else { return nil }
        return Date(timeIntervalSince1970: epochSeconds(value))
    }

    private static func epochSeconds(_ value: Double) -> TimeInterval {
        value > 1_000_000_000_000 ? value / 1000 : value
    }
}
