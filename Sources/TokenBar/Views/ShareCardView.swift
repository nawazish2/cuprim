import AppKit
import SwiftUI
import TokenBarCore

/// OpenUsage-style dark share card rendered to the pasteboard.
struct ShareCardView: View {
    let snapshots: [ProviderSnapshot]
    var showUsedPercent: Bool = true

    private let cardWidth: CGFloat = 360
    private let accent = Color(red: 0.22, green: 0.55, blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(snapshots) { snapshot in
                providerBlock(snapshot)
            }

            footer
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .frame(width: cardWidth)
        .background(Color.black)
        .environment(\.colorScheme, .dark)
    }

    private func providerBlock(_ snapshot: ProviderSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header(for: snapshot)

            VStack(alignment: .leading, spacing: 14) {
                switch snapshot.status {
                case .ok:
                    if snapshot.metrics.isEmpty {
                        Text("No metrics")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.45))
                    } else {
                        ForEach(snapshot.metrics) { metric in
                            metricBlock(metric)
                        }
                    }
                case .notLoggedIn:
                    Text("Not signed in")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                case .error(let message):
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(white: 0.14))
            )
        }
    }

    private func header(for snapshot: ProviderSnapshot) -> some View {
        HStack(spacing: 8) {
            ProviderIconView(id: snapshot.id, size: 18, foreground: .white)

            Text(snapshot.id.displayName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            if let plan = snapshot.planName, !plan.isEmpty {
                Text(plan)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func metricBlock(_ metric: Metric) -> some View {
        if metric.usedFraction != nil {
            VStack(alignment: .leading, spacing: 8) {
                Text(displayLabel(for: metric))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                GeometryReader { geo in
                    let used = max(0, min(1, metric.usedFraction ?? 0))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(accent)
                            .frame(width: max(used > 0 ? 6 : 0, geo.size.width * used))
                    }
                }
                .frame(height: 7)

                HStack {
                    Text(percentText(for: metric))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    if let reset = resetText(for: metric) {
                        Text(reset)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(displayLabel(for: metric))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                Spacer(minLength: 12)
                Text(metric.detail ?? "—")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Spacer(minLength: 0)
            Image(systemName: AppSymbols.app)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.4))
            Text("Monitor Your AI Subscriptions with TokenBar")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private func displayLabel(for metric: Metric) -> String {
        metric.label
            .replacingOccurrences(of: " limit", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " Limit", with: "")
    }

    private func percentText(for metric: Metric) -> String {
        if showUsedPercent {
            return QuotaFormatting.usedPercentLabel(usedFraction: metric.usedFraction) + " used"
        }
        return QuotaFormatting.remainingLabel(usedFraction: metric.usedFraction) + " left"
    }

    private func resetText(for metric: Metric) -> String? {
        guard metric.resetsAt != nil else { return nil }
        // Share cards always use relative countdown (matches OpenUsage).
        return QuotaFormatting.resetLabel(for: metric.resetsAt, absolute: false)
    }
}

extension ShareCardView {
    /// Rasterize the share card for the pasteboard / share targets.
    @MainActor
    static func renderImage(
        snapshots: [ProviderSnapshot],
        showUsedPercent: Bool,
        scale: CGFloat = 2
    ) -> NSImage? {
        guard !snapshots.isEmpty else { return nil }
        let view = ShareCardView(snapshots: snapshots, showUsedPercent: showUsedPercent)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.nsImage
    }
}
