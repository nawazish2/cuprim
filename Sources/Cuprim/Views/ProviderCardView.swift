import SwiftUI
import CuprimCore

/// Compact provider surface with native Liquid Glass depth.
struct ProviderCardView: View {
    let snapshot: ProviderSnapshot
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = false
    var isStale: Bool = false
    var isRefreshing: Bool = false

    @State private var isHovered = false

    private var sharedResetDate: Date? {
        let dates = snapshot.metrics.compactMap(\.resetsAt)
        guard !dates.isEmpty else { return nil }
        let labels = dates.map { QuotaFormatting.smartResetLabel(for: $0) }
        if let first = labels.first, labels.allSatisfy({ $0 == first }) {
            return dates.min()
        }
        let groups = Dictionary(grouping: zip(dates, labels), by: \.1)
        if let best = groups.max(by: { $0.value.count < $1.value.count }),
           best.value.count >= (dates.count + 1) / 2 {
            return best.value.map(\.0).min()
        }
        return nil
    }

    private var cardResetCaption: String? {
        guard let date = sharedResetDate else { return nil }
        return QuotaFormatting.resetLabel(for: date, absolute: absoluteResets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header

            switch snapshot.status {
            case .ok:
                if snapshot.isExhausted {
                    Text("Limit reached")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.red)
                }

                if snapshot.metrics.isEmpty {
                    Text("Limit details aren’t available right now.")
                        .font(.caption)
                        .foregroundStyle(GlassChrome.textTertiary)
                } else {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(snapshot.metrics) { metric in
                            MetricRowView(
                                metric: metric,
                                showUsedPercent: showUsedPercent,
                                absoluteResets: absoluteResets,
                                showReset: false,
                                emphasizeUpdate: isRefreshing
                            )
                        }
                    }

                    if let cardResetCaption {
                        Label(cardResetCaption, systemImage: "arrow.counterclockwise")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(GlassChrome.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if isStale {
                        Text("May be outdated")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(GlassChrome.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            case .notLoggedIn:
                Text(notLoggedInMessage)
                    .font(.caption)
                    .foregroundStyle(GlassChrome.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .error(let message):
                errorRow(message: friendlyError(message))
            }
        }
        .padding(GlassChrome.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .agentGlassCard()
        .scaleEffect(isHovered ? 1.008 : 1)
        .opacity(isStale && isOK ? 0.88 : 1)
        .fixedSize(horizontal: false, vertical: true)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(snapshot.id.displayName)
    }

    private var isOK: Bool {
        if case .ok = snapshot.status { return true }
        return false
    }

    private var header: some View {
        HStack(spacing: 10) {
            ProviderIconWell(id: snapshot.id, size: GlassChrome.providerIconSize)

            Text(snapshot.id.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GlassChrome.textPrimary)

            if let plan = snapshot.planName, !plan.isEmpty {
                PlanBadgeView(title: plan)
            }

            Spacer(minLength: 4)

            statusTrailing
        }
    }

    @ViewBuilder
    private var statusTrailing: some View {
        switch snapshot.status {
        case .ok:
            EmptyView()
        case .notLoggedIn:
            Image(systemName: AppSymbols.notSignedIn)
                .font(.caption2)
                .foregroundStyle(GlassChrome.textTertiary)
        case .error:
            Image(systemName: AppSymbols.error)
                .font(.caption2)
                .foregroundStyle(Color.orange)
        }
    }

    private func errorRow(message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: AppSymbols.error)
                .font(.caption)
                .foregroundStyle(Color.orange)
                .padding(.top, 1)
            Text(message)
                .font(.caption)
                .foregroundStyle(GlassChrome.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func friendlyError(_ message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("no weekly") || lower.contains("not available") || lower.contains("no limit") {
            return "Limit details aren’t available right now. Try refreshing in a moment."
        }
        if lower == "offline" || lower.contains("internet connection") || lower.contains("appears to be offline") {
            return "Offline. Last known usage is shown when we have it."
        }
        return message
    }

    private var notLoggedInMessage: String {
        switch snapshot.id {
        case .claude: "Sign in to Claude Desktop or run `claude` in Terminal."
        case .codex: "Sign in with the Codex CLI (`codex`)."
        case .cursor: "Open Cursor and sign in to your account."
        case .grok: "Sign in with Grok Build (`grok login`)."
        case .antigravity: "Open Antigravity or run `agy`."
        }
    }
}
