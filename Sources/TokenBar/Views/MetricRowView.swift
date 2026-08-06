import SwiftUI
import TokenBarCore

/// Compact meter row (ChatGPT-menu density):
///   Label
///   ████████░░
///   12% used · Resets …
struct MetricRowView: View {
    let metric: Metric
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = true

    @State private var showRemaining = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.12)) {
                            showRemaining.toggle()
                        }
                    }
                    .help("Toggle used / remaining")

                Spacer(minLength: 4)

                if let reset = resetText {
                    Text(reset)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
        }
        .onAppear { showRemaining = !showUsedPercent }
        .onChange(of: showUsedPercent) { _, used in
            showRemaining = !used
        }
    }

    private var primaryPercentText: String {
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
            let used = max(0, min(1, metric.usedFraction ?? 0))
            let w = used > 0 ? max(6, geo.size.width * used) : 0
            let color = QuotaFormatting.meterColor(usedFraction: metric.usedFraction)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.10))
                Capsule()
                    .fill(color.opacity(0.92))
                    .frame(width: w)
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
        .accessibilityLabel(primaryPercentText)
    }
}
