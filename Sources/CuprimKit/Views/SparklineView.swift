import SwiftUI
import CuprimCore

/// A thin usage trend line for one metric.
///
/// Deliberately minimal — no axes, no labels, no fill. The exact numbers are
/// already in the row above; this only has to answer "flat or climbing?". It
/// sits directly under the meter, so the newest reading is capped with a dot:
/// a bare stroke at this size reads as a second progress bar or a divider rule,
/// and the dot is what makes it read as a chart instead.
struct SparklineView: View {
    /// Oldest first. `nil` is a refresh that produced no reading and leaves a
    /// visible break in the line rather than a straight interpolation across it.
    let values: [Double?]
    var tint: Color = GlassChrome.usageBlue
    var height: CGFloat = 14

    private static let lineWidth: CGFloat = 1.5
    private static let dotRadius: CGFloat = 2

    private var hasReading: Bool {
        values.contains { $0 != nil }
    }

    var body: some View {
        if hasReading {
            // Copied into locals so the renderer closure captures only Sendable
            // values. `Canvas` can render asynchronously, so its closure is
            // `@Sendable` and must not capture `self` out of the view's
            // MainActor isolation.
            let points = values
            let stroke = tint.opacity(0.85)
            Canvas { context, size in
                let runs = Self.runs(for: points, in: size)
                for run in runs {
                    guard run.count > 1 else {
                        // A reading with no neighbour to join has to be a dot,
                        // or a gappy history draws nothing for it at all.
                        if let point = run.first {
                            context.fill(Self.dot(at: point), with: .color(stroke))
                        }
                        continue
                    }
                    context.stroke(
                        Self.linePath(run),
                        with: .color(stroke),
                        style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
                // Cap the newest reading, so the eye reads a series with a
                // "now" end rather than a rule drawn across the card.
                if let latest = runs.last?.last {
                    context.fill(Self.dot(at: latest), with: .color(stroke))
                }
            }
            .frame(height: height)
            .padding(.top, 2)
            .accessibilityHidden(true)
        }
    }

    /// Contiguous stretches of readings, split on the gaps. Plotted against a
    /// fixed 0–100% scale, matching the meter above it. An auto-scaled band
    /// would magnify two points of jitter into a dramatic climb, which is the
    /// opposite of what this is for.
    private static func runs(for values: [Double?], in size: CGSize) -> [[CGPoint]] {
        guard values.count > 1 else { return [] }
        // Keep the stroke and the end dot inside the bounds on every side, so
        // neither a reading at 0%/100% nor the newest-reading dot is sliced in
        // half by the canvas edge.
        let inset = max(lineWidth / 2, dotRadius)
        let usableWidth = max(0, size.width - inset * 2)
        let usableHeight = max(0, size.height - inset * 2)
        let stepX = usableWidth / CGFloat(values.count - 1)

        var runs: [[CGPoint]] = []
        var current: [CGPoint] = []
        for (index, value) in values.enumerated() {
            guard let value else {
                if !current.isEmpty { runs.append(current) }
                current = []
                continue
            }
            current.append(
                CGPoint(
                    x: inset + CGFloat(index) * stepX,
                    y: inset + (1 - CGFloat(Utilization.clamp01(value))) * usableHeight
                )
            )
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }

    private static func linePath(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        return path
    }

    private static func dot(at point: CGPoint) -> Path {
        Path(
            ellipseIn: CGRect(
                x: point.x - dotRadius,
                y: point.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
        )
    }
}
