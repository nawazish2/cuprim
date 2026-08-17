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
    @State private var showRefreshCheck = false

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
            if let snap = usage.snapshots[id], preferences.isEnabled(id) {
                return [snap]
            }
            return []
        }
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
                    available: preferences.orderedProviders.filter { preferences.isEnabled($0) }
                )
                .padding(.horizontal, GlassChrome.inset)
                .padding(.bottom, 8)
            }

            ScrollView(.vertical, showsIndicators: false) {
                GlassEffectContainer(spacing: GlassChrome.cardGap) {
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
                                    absoluteResets: preferences.absoluteResetTimes,
                                    isStale: usage.isSnapshotStale(snapshot),
                                    isRefreshing: usage.isRefreshing
                                )
                                .id(snapshot.id)
                            }
                        }
                    }
                    .padding(.horizontal, GlassChrome.inset)
                    .padding(.top, 2)
                    .padding(.bottom, GlassChrome.scrollBottomPad)
                }
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
            if case .provider(let id) = uiState.selectedTab,
               !preferences.isEnabled(id) {
                uiState.selectedTab = .overview
            }
        }
        .onChange(of: uiState.selectedTab) { _, tab in
            if case .provider(let id) = tab, usage.snapshots[id] == nil {
                Task { await usage.refresh() }
            }
        }
        .onChange(of: usage.isRefreshing) { was, isNow in
            guard was, !isNow else { return }
            showRefreshCheck = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1100))
                showRefreshCheck = false
            }
            if !reduceMotion {
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            CupBrandMark(size: 18, foreground: GlassChrome.textSecondary)

            VStack(alignment: .leading, spacing: 0) {
                Text("Cuprim")
                    .font(.headline.weight(.semibold))
                    .tracking(-0.15)
                    .foregroundStyle(GlassChrome.textPrimary)

                Text(updatedSubtitle)
                    .font(.caption2)
                    .foregroundStyle(GlassChrome.textTertiary)
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
                Image(systemName: showRefreshCheck ? "checkmark" : AppSymbols.refresh)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlassChrome.textSecondary)
                    .symbolEffect(.rotate, isActive: usage.isRefreshing && !reduceMotion)
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(refreshPulse ? 1.12 : 1.0)
                    .frame(width: 28, height: 28)
                    .background {
                        Circle().fill(Color.primary.opacity(0.08))
                            .overlay {
                                Circle().strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                            }
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

    private var updatedSubtitle: String {
        if let updated = QuotaFormatting.updatedLabel(for: usage.lastRefresh) {
            return "Updated " + updated
        }
        return "Your usage at a glance"
    }

    private var refreshHelp: String {
        if let updated = QuotaFormatting.updatedLabel(for: usage.lastRefresh) {
            return "Refresh (\(updated))"
        }
        return "Refresh"
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
        VStack(spacing: GlassChrome.cardGap) {
            ForEach(0..<3, id: \.self) { _ in
                skeletonCard
            }
        }
    }

    private var skeletonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 18, height: 18)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 72, height: 10)
                Spacer(minLength: 0)
            }
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.primary.opacity(0.07))
                            .frame(width: 54, height: 8)
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.primary.opacity(0.07))
                            .frame(width: 28, height: 8)
                    }
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: GlassChrome.meterHeight)
                }
            }
        }
        .padding(GlassChrome.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .agentGlassCard()
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading")
    }

    private var emptyProviderHint: String {
        guard case .provider(let id) = uiState.selectedTab else {
            return "This provider has no usage to show."
        }
        switch id {
        case .antigravity: return "Open Antigravity or run `agy`, then tap Refresh."
        case .claude: return "Sign in to Claude Desktop or run `claude` in Terminal."
        case .codex: return "Sign in with the Codex CLI (`codex`)."
        case .cursor: return "Open Cursor and sign in to your account."
        case .grok: return "Sign in with Grok Build (`grok login`)."
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(uiState.selectedTab == .overview ? "Nothing to show yet" : "No data")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GlassChrome.textPrimary)
            Text(
                uiState.selectedTab == .overview
                    ? "Sign in to Claude, Codex, Cursor, Grok, or Antigravity on this Mac."
                    : emptyProviderHint
            )
            .font(.caption)
            .foregroundStyle(GlassChrome.textSecondary)
            .fixedSize(horizontal: false, vertical: true)

            if uiState.selectedTab == .overview {
                Button("Open Settings…", action: onOpenSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 4)
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FooterScrim: View {
    var body: some View {
        Rectangle().fill(.thinMaterial)
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
