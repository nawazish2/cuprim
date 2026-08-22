import SwiftUI
import CuprimCore

/// Metric row: label, used/remaining button, compact meter.
struct MetricRowView: View {
    let metric: Metric
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = false
    var showReset: Bool = false
    /// Recent readings, oldest first. Empty renders nothing.
    var samples: [Double?] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var showRemaining = false
    @State private var animatedUsed: CGFloat = 0

    private var meterHeight: CGFloat { GlassChrome.meterHeight }
    private var isTotal: Bool { metric.kind == .total }

    private var targetUsed: CGFloat {
        guard let f = metric.usedFraction else { return 0 }
        return CGFloat(Utilization.clamp01(f))
    }

    private var isHighUsage: Bool {
        guard let used = metric.usedFraction else { return false }
        return Utilization.clamp01(used) >= 0.80
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HStack(spacing: 4) {
                    Text(metric.displayLabel)
                        .font(isTotal ? .caption.weight(.semibold) : .caption2.weight(.medium))
                        .foregroundStyle(GlassChrome.textSecondary)
                        .lineLimit(1)
                    if isHighUsage {
                        // A small dot, not the card-level triangle — this
                        // flags one metric row, not the whole provider.
                        Circle()
                            .fill(QuotaFormatting.meterColor(usedFraction: metric.usedFraction))
                            .frame(width: 5, height: 5)
                            .accessibilityHidden(true)
                    }
                }

                Spacer(minLength: 4)

                Button {
                    guard metric.usedFraction != nil else { return }
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.12)) {
                        showRemaining.toggle()
                    }
                } label: {
                    Text(primaryPercentText)
                        .font(
                            .system(isTotal ? .callout : .subheadline, design: .rounded)
                                .monospacedDigit()
                                .weight(.bold)
                        )
                        .foregroundStyle(QuotaFormatting.meterColor(usedFraction: metric.usedFraction))
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
                .disabled(metric.usedFraction == nil)
                .help(metric.usedFraction == nil ? "" : "Toggle used / remaining")
                .accessibilityLabel(voiceOverValue)
                .accessibilityHint("Shows used or remaining percent")
            }

            meter

            SparklineView(
                values: samples,
                tint: QuotaFormatting.meterColor(usedFraction: metric.usedFraction)
            )

            if showReset, let reset = resetText {
                Text(reset)
                    .font(.caption2)
                    .foregroundStyle(GlassChrome.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            showRemaining = !showUsedPercent
            animateFill(to: targetUsed, immediate: reduceMotion)
        }
        .onChange(of: showUsedPercent) { _, used in
            showRemaining = !used
        }
        .onChange(of: targetUsed) { _, newValue in
            animateFill(to: newValue, immediate: reduceMotion)
        }
    }

    private func animateFill(to value: CGFloat, immediate: Bool) {
        if immediate {
            animatedUsed = value
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                animatedUsed = value
            }
        }
    }

    private var primaryPercentText: String {
        if metric.usedFraction == nil {
            return metric.detail ?? "—"
        }
        if showRemaining {
            return QuotaFormatting.remainingLabel(usedFraction: metric.usedFraction)
        }
        return QuotaFormatting.usedPercentLabel(usedFraction: metric.usedFraction)
    }

    private var voiceOverValue: String {
        let label = metric.displayLabel
        if metric.usedFraction == nil {
            return "\(label) unavailable"
        }
        if showRemaining {
            return "\(label) \(QuotaFormatting.remainingLabel(usedFraction: metric.usedFraction)) remaining. Currently showing remaining."
        }
        return "\(label) \(QuotaFormatting.usedPercentLabel(usedFraction: metric.usedFraction)) used. Currently showing used."
    }

    private var resetText: String? {
        guard metric.resetsAt != nil else { return nil }
        return QuotaFormatting.resetLabel(for: metric.resetsAt, absolute: absoluteResets)
    }

    private var meter: some View {
        GeometryReader { geo in
            let used = animatedUsed
            let w = geo.size.width * used
            let color = QuotaFormatting.meterColor(usedFraction: metric.usedFraction)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(contrast == .increased ? 0.18 : 0.11))
                    .frame(height: meterHeight)

                if used > 0.001 {
                    Capsule()
                        .fill(color.opacity(0.94))
                        .frame(width: max(w, meterHeight * 0.45), height: meterHeight)
                }
            }
            .frame(width: geo.size.width, height: meterHeight, alignment: .leading)
        }
        .frame(height: meterHeight)
        .accessibilityHidden(true)
    }
}
