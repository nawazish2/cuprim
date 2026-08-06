import SwiftUI
import TokenBarCore

/// Compact meter row:
///   Label
///   ████████░░
///   12% used · Resets …
struct MetricRowView: View {
    let metric: Metric
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = false

    @State private var showRemaining = false

    private let meterHeight: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(metric.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            meter

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(primaryPercentText)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(QuotaFormatting.meterColor(usedFraction: metric.usedFraction))
                    .contentTransition(.numericText())
                    .layoutPriority(1)
                    .onTapGesture {
                        guard metric.usedFraction != nil else { return }
                        withAnimation(.snappy(duration: 0.12)) {
                            showRemaining.toggle()
                        }
                    }
                    .help(metric.usedFraction == nil ? "" : "Toggle used / remaining")

                Spacer(minLength: 4)

                if let reset = resetText {
                    Text(reset)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .onAppear { showRemaining = !showUsedPercent }
        .onChange(of: showUsedPercent) { _, used in
            showRemaining = !used
        }
    }

    private var primaryPercentText: String {
        // Always show a percent (or em dash) when we have a meter row.
        if metric.usedFraction == nil {
            return metric.detail ?? "—"
        }
        if showRemaining {
            return QuotaFormatting.remainingLabel(usedFraction: metric.usedFraction) + " left"
        }
        return QuotaFormatting.usedPercentLabel(usedFraction: metric.usedFraction) + " used"
    }

    private var resetText: String? {
        guard metric.resetsAt != nil else { return nil }
        return QuotaFormatting.resetLabel(for: metric.resetsAt, absolute: absoluteResets)
    }

    private var meter: some View {
        GeometryReader { geo in
            let fraction = metric.usedFraction.map { Utilization.clamp01($0) }
            let used = fraction ?? 0
            // Exact proportional width — no min stub that fattens high-usage bars.
            let w = geo.size.width * used
            let color = QuotaFormatting.meterColor(usedFraction: metric.usedFraction)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.10))
                    .frame(height: meterHeight)
                if used > 0 {
                    Capsule()
                        .fill(color.opacity(0.92))
                        .frame(width: w, height: meterHeight)
                }
            }
            .frame(width: geo.size.width, height: meterHeight, alignment: .leading)
        }
        .frame(height: meterHeight)
        .accessibilityLabel(primaryPercentText)
    }
}
