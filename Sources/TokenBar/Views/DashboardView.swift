import SwiftUI
import TokenBarCore

/// ChatGPT-style clean menu panel:
/// one glass shell · flat list · compact meters · pinned Settings / Quit.
struct DashboardView: View {
    @Bindable var usage: UsageStore
    @Bindable var preferences: PreferencesStore
    @Bindable var uiState: DashboardUIState
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, GlassChrome.inset)
                .padding(.top, 11)
                .padding(.bottom, 8)

            if !tabProviders.isEmpty || usage.isRefreshing {
                ProviderTabBar(
                    selection: $uiState.selectedTab,
                    available: tabProviders.isEmpty
                        ? preferences.orderedProviders.filter { preferences.isEnabled($0) }
                        : tabProviders
                )
                .padding(.horizontal, GlassChrome.inset)
                .padding(.bottom, 4)
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if usage.isRefreshing && !usage.hasAnyData {
                        loadingState
                    } else if filteredSnapshots.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(filteredSnapshots.enumerated()), id: \.element.id) { index, snapshot in
                            ProviderCardView(
                                snapshot: snapshot,
                                showUsedPercent: preferences.showUsedPercent,
                                absoluteResets: preferences.absoluteResetTimes,
                                isStale: usage.isSnapshotStale(snapshot),
                                showDivider: index > 0
                            )
                            .id(snapshot.id)
                        }
                    }
                }
                .padding(.horizontal, GlassChrome.inset)
                .padding(.top, 6)
                .padding(.bottom, 8)
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
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.15),
            value: uiState.selectedTab
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: AppSymbols.app)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("TokenBar")
                .font(.body.weight(.semibold))

            Spacer(minLength: 4)

            Button {
                Task { await usage.refresh() }
            } label: {
                if usage.isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: AppSymbols.refresh)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(usage.isRefreshing)
            .help("Refresh")
            .keyboardShortcut("r", modifiers: .command)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.10))
                .frame(height: 0.5)

            VStack(spacing: 1) {
                NativeMenuRowButton(title: "Settings…", shortcut: "⌘,", action: onOpenSettings)
                    .keyboardShortcut(",", modifiers: .command)

                NativeMenuRowButton(title: "Quit TokenBar", shortcut: "⌘Q", action: onQuit)
                    .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - States

    private var loadingState: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading…")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(uiState.selectedTab == .overview ? "No providers signed in" : "No data")
                .font(.subheadline.weight(.medium))
            Text("Sign in to Claude, Codex, Cursor, or Grok — or open Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - NSMenu-style blue hover (matches system menu selection)

private struct NativeMenuRowButton: View {
    let title: String
    let shortcut: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer(minLength: 12)
                Text(shortcut)
                    .font(.caption)
                    .monospacedDigit()
                    .opacity(isHovered ? 0.9 : 0.45)
            }
            .foregroundStyle(isHovered ? Color.white : Color.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
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
