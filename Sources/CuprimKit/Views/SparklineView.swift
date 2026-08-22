import SwiftUI
import CuprimCore

/// A thin usage trend line for one metric.
///
/// Deliberately minimal — no axes, no fill, no labels. The exact numbers are
/// already in the row above; this only has to answer "flat or climbing?".
struct SparklineView: View {
    /// Oldest first. `nil` is a refresh that produced no reading and leaves a
    /// visible break in the line rather than a straight interpolation across it.
    let values: [Double?]
    var tint: Color = GlassChrome.usageBlue
    var height: CGFloat = 14

    private var drawableCount: Int {
        values.compactMap { $0 }.count
    }

    var body: some View {
        if drawableCount >= 2 {
            Canvas { context, size in
                context.stroke(
                    path(in: size),
                    with: .color(tint.opacity(0.75)),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: height)
            .accessibilityHidden(true)
        }
    }

    /// Plotted against a fixed 0–100% scale, matching the meter above it. An
    /// auto-scaled band would magnify two points of jitter into a dramatic
    /// climb, which is the opposite of what this is for.
    private func path(in size: CGSize) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        let stepX = size.width / CGFloat(values.count - 1)
        var started = false

        for (index, value) in values.enumerated() {
            guard let value else {
                started = false
                continue
            }
            let point = CGPoint(
                x: CGFloat(index) * stepX,
                y: (1 - CGFloat(Utilization.clamp01(value))) * size.height
            )
            if started {
                path.addLine(to: point)
            } else {
                path.move(to: point)
                started = true
            }
        }
        return path
    }
}
