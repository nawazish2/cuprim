import Foundation

/// Where a run of samples sharing one reset time begins.
///
/// Reset times are stored as runs, not per sample: a window's reset changes a
/// handful of times a week, so run-length encoding costs almost nothing and
/// gives consumers exact window boundaries. That is what lets `BurnRate` slice
/// samples to a single window instead of fitting a slope across the sawtooth.
public struct WindowRun: Codable, Equatable, Sendable {
    public let startIndex: Int
    public let resetsAt: Date?

    public init(startIndex: Int, resetsAt: Date?) {
        self.startIndex = startIndex
        self.resetsAt = resetsAt
    }
}

/// One metric's usage over time on a fixed bucket grid.
///
/// Values are basis points (`used × 10_000`) rather than `Double`s, and a gap
/// is `noSample`, never `0` — writing a zero for "we didn't hear back" would
/// turn an unknown into a confident, alert-suppressing reading the moment it
/// round-tripped through disk.
public struct MetricSeries: Codable, Equatable, Sendable {
    public static let noSample = -1
    public static let scale = 10_000.0

    public let provider: ProviderID
    public let metricID: String
    public let bucketSeconds: Int
    public private(set) var firstBucket: Int
    public private(set) var values: [Int]
    public private(set) var windows: [WindowRun]

    public init(
        provider: ProviderID,
        metricID: String,
        bucketSeconds: Int,
        firstBucket: Int = 0,
        values: [Int] = [],
        windows: [WindowRun] = []
    ) {
        self.provider = provider
        self.metricID = metricID
        self.bucketSeconds = max(1, bucketSeconds)
        self.firstBucket = firstBucket
        self.values = values
        self.windows = windows
    }

    public func bucket(for date: Date) -> Int {
        Int((date.timeIntervalSince1970 / Double(bucketSeconds)).rounded(.down))
    }

    public static func encode(_ usedFraction: Double?) -> Int {
        guard let usedFraction else { return noSample }
        return Int((Utilization.clamp01(usedFraction) * scale).rounded())
    }

    public static func decode(_ value: Int) -> Double? {
        value < 0 ? nil : Utilization.clamp01(Double(value) / scale)
    }

    /// Last write wins within a bucket. Samples older than the series start are
    /// dropped rather than reordering the grid.
    public mutating func record(usedFraction: Double?, resetsAt: Date?, at date: Date) {
        let target = bucket(for: date)
        let encoded = Self.encode(usedFraction)

        guard !values.isEmpty else {
            firstBucket = target
            values = [encoded]
            windows = [WindowRun(startIndex: 0, resetsAt: resetsAt)]
            return
        }

        let index = target - firstBucket
        guard index >= 0 else { return }

        if index < values.count {
            values[index] = encoded
        } else {
            // Gaps between refreshes stay explicitly unknown.
            values.append(contentsOf: Array(repeating: Self.noSample, count: index - values.count))
            values.append(encoded)
        }
        noteWindow(resetsAt: resetsAt, at: min(index, values.count - 1))
    }

    private mutating func noteWindow(resetsAt: Date?, at index: Int) {
        guard let last = windows.last else {
            windows = [WindowRun(startIndex: index, resetsAt: resetsAt)]
            return
        }
        guard last.resetsAt != resetsAt else { return }
        if last.startIndex == index {
            windows[windows.count - 1] = WindowRun(startIndex: index, resetsAt: resetsAt)
        } else {
            windows.append(WindowRun(startIndex: index, resetsAt: resetsAt))
        }
    }

    /// Drops buckets older than `retaining`, keeping the run that covers the
    /// retained region so the active window's reset time survives the trim.
    public mutating func trim(retaining: TimeInterval, now: Date) {
        guard !values.isEmpty else { return }
        let cutoff = bucket(for: now.addingTimeInterval(-retaining))
        let drop = min(max(0, cutoff - firstBucket), values.count)
        guard drop > 0 else { return }

        values.removeFirst(drop)
        firstBucket += drop

        var shifted: [WindowRun] = []
        var carried: WindowRun?
        for run in windows {
            let start = run.startIndex - drop
            if start < 0 {
                carried = WindowRun(startIndex: 0, resetsAt: run.resetsAt)
            } else {
                shifted.append(WindowRun(startIndex: start, resetsAt: run.resetsAt))
            }
        }
        if let carried, shifted.first?.startIndex != 0 {
            shifted.insert(carried, at: 0)
        }
        windows = shifted
    }

    public func date(atIndex index: Int) -> Date {
        Date(timeIntervalSince1970: Double(firstBucket + index) * Double(bucketSeconds))
    }

    /// The newest `limit` buckets, oldest first, gaps preserved as nil.
    public func recentValues(limit: Int) -> [Double?] {
        guard limit > 0 else { return [] }
        return values.suffix(limit).map(Self.decode)
    }

    /// Samples belonging to the most recent window, ready for `BurnRate`.
    public func currentWindow() -> (samples: [BurnSample], resetsAt: Date?) {
        guard let run = windows.last, run.startIndex < values.count else {
            return ([], nil)
        }
        var samples: [BurnSample] = []
        for index in run.startIndex..<values.count {
            guard let used = Self.decode(values[index]) else { continue }
            samples.append(BurnSample(at: date(atIndex: index), usedFraction: used))
        }
        return (samples, run.resetsAt)
    }
}

/// The whole on-disk history. Bounded by construction: one fixed-cadence grid
/// per metric, trimmed to `retention` on every load and every flush.
public struct UsageHistory: Codable, Sendable {
    public static let currentVersion = 1
    public static let bucketSeconds = 300
    public static let retention: TimeInterval = 7 * 24 * 60 * 60

    public var version: Int
    public var series: [MetricSeries]

    public init(version: Int = UsageHistory.currentVersion, series: [MetricSeries] = []) {
        self.version = version
        self.series = series
    }

    public func series(provider: ProviderID, metricID: String) -> MetricSeries? {
        series.first { $0.provider == provider && $0.metricID == metricID }
    }

    public mutating func record(snapshot: ProviderSnapshot, at date: Date) {
        guard case .ok = snapshot.status else { return }
        for metric in snapshot.metrics {
            let index = series.firstIndex {
                $0.provider == snapshot.id && $0.metricID == metric.id
            }
            if let index {
                series[index].record(
                    usedFraction: metric.usedFraction,
                    resetsAt: metric.resetsAt,
                    at: date
                )
            } else {
                var fresh = MetricSeries(
                    provider: snapshot.id,
                    metricID: metric.id,
                    bucketSeconds: Self.bucketSeconds
                )
                fresh.record(
                    usedFraction: metric.usedFraction,
                    resetsAt: metric.resetsAt,
                    at: date
                )
                series.append(fresh)
            }
        }
    }

    public mutating func trim(now: Date) {
        for index in series.indices {
            series[index].trim(retaining: Self.retention, now: now)
        }
        series.removeAll { $0.values.isEmpty }
    }
}
