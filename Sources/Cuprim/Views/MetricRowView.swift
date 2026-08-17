import SwiftUI
import CuprimCore

/// Metric row: restrained label/value hierarchy with a compact semantic meter.
struct MetricRowView: View {
    let metric: Metric
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = false
    var showReset: Bool = false
    var emphasizeUpdate: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRemaining = false
    @State private var animatedUsed: CGFloat = 0
    @State private var showGlow = false

    private var meterHeight: CGFloat { GlassChrome.meterHeight }
    private var isTotal: Bool {
        metric.id.lowercased().contains("total") || metric.label.lowercased() == "total"
    }

    private var targetUsed: CGFloat {
        guard let f = metric.usedFraction else { return 0 }
        return CGFloat(Utilization.clamp01(f))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(metric.displayLabel)
                    .font(isTotal ? .caption.weight(.semibold) : .caption2.weight(.medium))
                    .foregroundStyle(GlassChrome.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(primaryPercentText)
                    .font(
                        .system(isTotal ? .subheadline : .callout, design: .rounded)
                            .monospacedDigit()
                            .weight(.bold)
                    )
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
            }

            meter

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
            if emphasizeUpdate, !reduceMotion {
                showGlow = true
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(420))
                    showGlow = false
                }
            }
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
                    .fill(Color.primary.opacity(0.11))
                    .frame(height: meterHeight)

                if used > 0.001 {
                    Capsule()
                        .fill(color.opacity(0.94))
                        .frame(width: max(w, meterHeight * 0.45), height: meterHeight)
                        .shadow(
                            color: showGlow ? color.opacity(0.28) : .clear,
                            radius: showGlow ? 2 : 0,
                            y: 0
                        )
                }
            }
            .frame(width: geo.size.width, height: meterHeight, alignment: .leading)
        }
        .frame(height: meterHeight)
        .accessibilityLabel("\(metric.displayLabel) \(primaryPercentText)")
    }
}
