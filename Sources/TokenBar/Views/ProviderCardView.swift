import SwiftUI
import TokenBarCore

/// Flat list section for one provider — no nested glass card (ChatGPT-clean).
struct ProviderCardView: View {
    let snapshot: ProviderSnapshot
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = false
    var isStale: Bool = false
    var showDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showDivider {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 0.5)
                    .padding(.bottom, 14)
            }

            VStack(alignment: .leading, spacing: 10) {
                header

                switch snapshot.status {
                case .ok:
                    if snapshot.metrics.isEmpty {
                        Text("No metrics")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        VStack(alignment: .leading, spacing: 11) {
                            ForEach(snapshot.metrics) { metric in
                                MetricRowView(
                                    metric: metric,
                                    showUsedPercent: showUsedPercent,
                                    absoluteResets: absoluteResets
                                )
                            }
                        }
                    }
                case .notLoggedIn:
                    Text(notLoggedInMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                case .error(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .opacity(isStale && isOK ? 0.8 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(snapshot.id.displayName)
    }

    private var isOK: Bool {
        if case .ok = snapshot.status { return true }
        return false
    }

    private var header: some View {
        HStack(spacing: 7) {
            ProviderIconView(id: snapshot.id, size: 13)

            Text(snapshot.id.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            if let plan = snapshot.planName, !plan.isEmpty {
                Text(plan)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            statusAccessory
        }
    }

    @ViewBuilder
    private var statusAccessory: some View {
        switch snapshot.status {
        case .ok:
            EmptyView()
        case .notLoggedIn:
            Image(systemName: AppSymbols.notSignedIn)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        case .error:
            Image(systemName: AppSymbols.error)
                .font(.caption2)
                .foregroundStyle(.orange.opacity(0.85))
        }
    }

    private var notLoggedInMessage: String {
        switch snapshot.id {
        case .claude: "No Claude login. Open Claude Desktop or run `claude`."
        case .codex: "Sign in with Codex CLI (`codex`)."
        case .cursor: "Open Cursor and sign in."
        case .grok: "Sign in with Grok Build (`grok login`)."
        }
    }
}
