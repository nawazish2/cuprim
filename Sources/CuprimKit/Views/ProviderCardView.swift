import SwiftUI
import CuprimCore

struct ProviderCardView: View {
    let id: ProviderID
    let presentation: ProviderPresentation
    var snapshot: ProviderSnapshot?
    var showUsedPercent: Bool = true
    var absoluteResets: Bool = false
    var copiedCommand: String?
    var onCopy: (String) -> Void = { _ in }
    var onRefresh: () -> Void = {}

    private var displaySnapshot: ProviderSnapshot? {
        presentation.snapshot ?? snapshot
    }

    private var resetPresentation: ResetPresentation {
        displaySnapshot?.resetPresentation() ?? ResetPresentation(shared: nil, perMetric: false)
    }

    private var sharedResetDate: Date? { resetPresentation.shared }

    private var showsPerMetricReset: Bool { resetPresentation.perMetric }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            content
        }
        .padding(GlassChrome.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cuprimGroupedCard()
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(id.displayName)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ProviderIconWell(id: id, size: GlassChrome.providerIconSize)

            Text(id.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GlassChrome.textPrimary)

            if let plan = displaySnapshot?.planName, !plan.isEmpty, showsMeters {
                PlanBadgeView(title: plan)
            }

            Spacer(minLength: 4)
        }
    }

    private var showsMeters: Bool {
        switch presentation {
        case .ready, .stale: return true
        case .failed(_, let lastGood): return lastGood != nil
        default: return false
        }
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
        case .loading:
            Text("Checking…")
                .font(.caption)
                .foregroundStyle(GlassChrome.textSecondary)
        case .ready(let snapshot):
            meters(snapshot, staleCaption: nil)
        case .stale(let snapshot, let failure):
            meters(snapshot, staleCaption: staleCaption(failure: failure, fetchedAt: snapshot.fetchedAt))
        case .signedOut(let kind):
            signedOut(kind)
        case .failed(let kind, let lastGood):
            if let lastGood {
                meters(lastGood, staleCaption: kind.userMessage)
            } else {
                failed(kind)
            }
        }
    }

    @ViewBuilder
    private func meters(_ snapshot: ProviderSnapshot, staleCaption: String?) -> some View {
        if snapshot.isExhausted {
            // Distinct glyph (triangle) from the per-metric dot badge below,
            // so "whole provider capped" reads differently from "this one
            // row is high" at a glance.
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("Limit reached")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(GlassChrome.usageRed)
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
                        showReset: showsPerMetricReset
                    )
                }
            }

            if let date = sharedResetDate {
                Label(QuotaFormatting.resetLabel(for: date, absolute: absoluteResets), systemImage: "arrow.counterclockwise")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(GlassChrome.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if let staleCaption {
                Text(staleCaption)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(GlassChrome.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func signedOut(_ kind: ProviderFailureKind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kind == .sessionExpired ? "Session expired. Sign in again." : ProviderLoginAction.hint(for: id))
                .font(.caption)
                .foregroundStyle(GlassChrome.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            actionButtons(kind: kind)
        }
    }

    private func failed(_ kind: ProviderFailureKind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kind.userMessage)
                .font(.caption)
                .foregroundStyle(GlassChrome.textSecondary)
            actionButtons(kind: kind)
        }
    }

    @ViewBuilder
    private func actionButtons(kind: ProviderFailureKind) -> some View {
        HStack(spacing: 8) {
            let action = ProviderLoginAction.primary(for: id)
            switch action {
            case .copyCommand(let command):
                Button(copiedCommand == command ? "Copied" : action.title) {
                    onCopy(command)
                    action.perform()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            case .openApp:
                Button(action.title) { action.perform() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            case .refresh:
                EmptyView()
            }

            if kind.isTransient || kind == .malformedResponse {
                Button("Refresh", action: onRefresh)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }

    private func staleCaption(failure: ProviderFailureKind?, fetchedAt: Date) -> String {
        let age = QuotaFormatting.updatedLabel(for: fetchedAt) ?? "earlier"
        if let failure, failure.isTransient {
            return "\(failure.userMessage). Last saved \(age)."
        }
        return "Last saved \(age)."
    }
}
