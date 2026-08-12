import SwiftUI
import CuprimCore

/// Native-minimal Liquid Glass panel — solid cards, not glass data.
struct DashboardView: View {
    @Bindable var usage: UsageStore
    @Bindable var preferences: PreferencesStore
    @Bindable var uiState: DashboardUIState
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var refreshPulse = false

    private let panelWidth = GlassChrome.panelWidth
    private let panelHeight = GlassChrome.panelHeight

    private var tabProviders: [ProviderID] {
        preferences.orderedProviders.filter { id in
            guard preferences.isEnabled(id) else { return false }
            guard let snap = usage.snapshots[id] else { return usage.isRefreshing }
            if preferences.hideLoggedOutProviders, case .notLoggedIn = snap.status {
                return false
            }
            return true
        }
    }

    private var filteredSnapshots: [ProviderSnapshot] {
        switch uiState.selectedTab {
        case .overview:
            return usage.visibleSnapshots
        case .provider(let id):
            return usage.visibleSnapshots.filter { $0.id == id }
        }
    }

    private var selectedProviderSnapshot: ProviderSnapshot? {
        guard case .provider(let id) = uiState.selectedTab else { return nil }
        return filteredSnapshots.first { $0.id == id }
            ?? usage.snapshots[id]
    }

    /// Exhausted provider names for the overview banner (unique, ordered).
    private var exhaustedProviders: [ProviderID] {
        preferences.orderedProviders.compactMap { id in
            guard let snap = usage.snapshots[id], preferences.isEnabled(id) else { return nil }
            return snap.isExhausted ? id : nil
        }
    }

    private var exhaustedBannerCopy: String? {
        let names = exhaustedProviders.map(\.displayName)
        guard !names.isEmpty else { return nil }
        switch names.count {
        case 1:
            return "\(names[0]) limit reached"
        case 2:
            return "\(names[0]) & \(names[1]) limit reached"
        default:
            return "\(names.count) providers limit reached"
        }
    }

    private var firstExhaustedTab: ProviderTab? {
        guard let id = exhaustedProviders.first else { return nil }
        return .provider(id)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, GlassChrome.inset)
                .padding(.top, 10)
                .padding(.bottom, 8)

            if !tabProviders.isEmpty || usage.isRefreshing {
                ProviderTabBar(
                    selection: $uiState.selectedTab,
                    available: tabProviders.isEmpty
                        ? preferences.orderedProviders.filter { preferences.isEnabled($0) }
                        : tabProviders
                )
                .padding(.horizontal, GlassChrome.inset)
                .padding(.bottom, 8)
            }

            if let exhaustedBannerCopy, uiState.selectedTab == .overview {
                attentionStrip(text: exhaustedBannerCopy)
                    .padding(.horizontal, GlassChrome.inset)
                    .padding(.bottom, 8)
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: GlassChrome.cardGap) {
                    if usage.isRefreshing && !usage.hasAnyData {
                        loadingState
                    } else if filteredSnapshots.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredSnapshots) { snapshot in
                            ProviderCardView(
                                snapshot: snapshot,
                                showUsedPercent: preferences.showUsedPercent,
                                absoluteResets: false,
                                isStale: usage.isSnapshotStale(snapshot),
                                isRefreshing: usage.isRefreshing,
                                horizon: snapshot.metrics.first.map {
                                    usage.horizon(for: snapshot.id, metricID: $0.id)
                                }
                            )
                            .id(snapshot.id)
                        }

                        if case .provider = uiState.selectedTab,
                           let snap = selectedProviderSnapshot {
                            providerDetailFill(for: snap)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, GlassChrome.inset)
                .padding(.top, 2)
                .padding(.bottom, GlassChrome.scrollBottomPad)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .layoutPriority(-1)
            .clipped()

            footer
        }
        .frame(width: panelWidth, height: panelHeight, alignment: .top)
        .agentGlassPanel()
        .frame(width: panelWidth, height: panelHeight)
        .onChange(of: tabProviders.map(\.rawValue).joined(separator: ",")) { _, _ in
            if case .provider(let id) = uiState.selectedTab, !tabProviders.contains(id) {
                uiState.selectedTab = .overview
            }
        }
        .onChange(of: usage.isRefreshing) { was, isNow in
            // Pulse scale when a refresh finishes successfully.
            if was, !isNow, !reduceMotion {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    refreshPulse = true
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(180))
                    withAnimation(.easeOut(duration: 0.14)) {
                        refreshPulse = false
                    }
                }
            }
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.86),
            value: uiState.selectedTab
        )
    }

    // MARK: - Banner

    private func attentionStrip(text: String) -> some View {
        Button {
            if let firstExhaustedTab {
                if reduceMotion {
                    uiState.selectedTab = firstExhaustedTab
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        uiState.selectedTab = firstExhaustedTab
                    }
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.red.opacity(0.85))
                Text(text)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(GlassChrome.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(GlassChrome.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.16), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
        .help("Show first exhausted provider")
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            CupBrandMark(size: 17, foreground: GlassChrome.textSecondary)

            Text("Cuprim")
                .font(.title2.weight(.bold))
                .tracking(-0.35)
                .foregroundStyle(GlassChrome.textPrimary)

            if let updated = QuotaFormatting.updatedLabel(for: usage.lastRefresh) {
                Text(updated)
                    .font(.caption2)
                    .foregroundStyle(Color.primary.opacity(0.45))
                    .padding(.leading, 1)
            }

            Spacer(minLength: 4)

            Button {
                if !reduceMotion {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                        refreshPulse = true
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(120))
                        withAnimation(.easeOut(duration: 0.12)) {
                            refreshPulse = false
                        }
                    }
                }
                Task { await usage.refresh() }
            } label: {
                Image(systemName: AppSymbols.refresh)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlassChrome.textSecondary)
                    .symbolEffect(.rotate, isActive: usage.isRefreshing)
                    .scaleEffect(refreshPulse ? 1.12 : 1.0)
                    .frame(width: 28, height: 28)
                    .background {
                        Circle()
                            .fill(Color.primary.opacity(0.10))
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(usage.isRefreshing)
            .help(refreshHelp)
            .keyboardShortcut("r", modifiers: .command)
            .opacity(usage.isRefreshing ? 0.7 : 1)
        }
    }

    private var refreshHelp: String {
        if let updated = QuotaFormatting.updatedLabel(for: usage.lastRefresh) {
            return "Refresh (\(updated))"
        }
        return "Refresh"
    }

    // MARK: - Provider detail (honest fill for single-tab empty space)

    @ViewBuilder
    private func providerDetailFill(for snapshot: ProviderSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let next = snapshot.nextResetAt {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GlassChrome.textTertiary)
                    Text(QuotaFormatting.smartResetLabel(for: next))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GlassChrome.textSecondary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 2)
            }

            if let blurb = providerStatusBlurb(for: snapshot) {
                Text(blurb)
                    .font(.caption)
                    .foregroundStyle(GlassChrome.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func providerStatusBlurb(for snapshot: ProviderSnapshot) -> String? {
        switch snapshot.status {
        case .ok:
            if snapshot.isExhausted {
                return "Limit reached. Check the meters above for which window is full."
            }
            return nil
        case .notLoggedIn:
            return "Sign in to see live limits for this provider."
        case .error:
            return "Couldn’t load this provider’s limits. Try Refresh."
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 0.5)

            VStack(spacing: 1) {
                NativeMenuRowButton(title: "Settings…", shortcut: "⌘,", action: onOpenSettings)
                    .keyboardShortcut(",", modifiers: .command)

                NativeMenuRowButton(title: "Quit Cuprim", shortcut: "⌘Q", action: onQuit)
                    .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 5)
            .padding(.top, 2)
            .padding(.bottom, 5)
        }
        .background { FooterScrim() }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var loadingState: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading…")
                .font(.caption.weight(.medium))
                .foregroundStyle(GlassChrome.textSecondary)
            Spacer()
        }
        .padding(.vertical, 16)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(uiState.selectedTab == .overview ? "No providers signed in" : "No data")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GlassChrome.textPrimary)
            Text("Sign in to Claude, Codex, Cursor, or Grok — or open Settings.")
                .font(.caption)
                .foregroundStyle(GlassChrome.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FooterScrim: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(
                colorScheme == .dark
                    ? GlassChrome.footerScrimDark
                    : GlassChrome.footerScrimLight
            )
    }
}

private struct NativeMenuRowButton: View {
    let title: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.callout.weight(.medium))
                Spacer(minLength: 12)
                Text(shortcut)
                    .font(.caption2.weight(.medium))
                    .monospacedDigit()
                    .opacity(isHovered ? 0.95 : 0.62)
            }
            .foregroundStyle(isHovered ? Color.white : GlassChrome.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.accentColor : Color.clear)
            }
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.08)) {
                isHovered = hovering
            }
        }
    }
}
