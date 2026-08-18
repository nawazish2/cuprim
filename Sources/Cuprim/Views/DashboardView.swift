import AppKit
import SwiftUI
import CuprimCore

/// Native-minimal Liquid Glass panel — one glass shell, grouped data.
struct DashboardView: View {
    @Bindable var usage: UsageStore
    @Bindable var preferences: PreferencesStore
    @Bindable var uiState: DashboardUIState
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var copiedCommand: String?

    private let panelWidth = GlassChrome.panelWidth
    private let panelHeight = GlassChrome.panelHeight

    private var tabProviders: [ProviderID] {
        preferences.orderedProviders.filter { preferences.isEnabled($0) }
    }

    private var filteredIDs: [ProviderID] {
        switch uiState.selectedTab {
        case .overview:
            return tabProviders.filter { id in
                if preferences.hideLoggedOutProviders, !preferences.showsFirstLaunchSetup {
                    if case .signedOut = usage.presentation(for: id) { return false }
                }
                return true
            }
        case .provider(let id):
            return preferences.isEnabled(id) ? [id] : []
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, GlassChrome.inset)
                .padding(.top, 10)
                .padding(.bottom, 8)

            if !tabProviders.isEmpty {
                ProviderTabBar(
                    selection: $uiState.selectedTab,
                    available: tabProviders
                )
                .padding(.horizontal, GlassChrome.inset)
                .padding(.bottom, 8)
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: GlassChrome.cardGap) {
                    if usage.isOffline {
                        offlineBanner
                    }

                    if preferences.showsFirstLaunchSetup, uiState.selectedTab == .overview {
                        firstLaunchIntro
                    }

                    if filteredIDs.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredIDs, id: \.self) { id in
                            ProviderCardView(
                                id: id,
                                presentation: usage.presentation(for: id),
                                snapshot: usage.snapshots[id],
                                showUsedPercent: preferences.showUsedPercent,
                                absoluteResets: preferences.absoluteResetTimes,
                                isStale: usage.snapshots[id].map(usage.isSnapshotStale) ?? false,
                                copiedCommand: copiedCommand,
                                onCopy: copy(_:),
                                onRefresh: { Task { await usage.refresh() } }
                            )
                            .id(id)
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
            .accessibilityElement(children: .contain)
            .accessibilityLabel(usage.isRefreshing ? "Refreshing usage" : "Usage")

            footer
        }
        .frame(width: panelWidth, height: panelHeight, alignment: .top)
        .cuprimGlassPanel()
        .frame(width: panelWidth, height: panelHeight)
        .onChange(of: tabProviders.map(\.rawValue).joined(separator: ",")) { _, _ in
            if case .provider(let id) = uiState.selectedTab,
               !preferences.isEnabled(id) {
                uiState.selectedTab = .overview
            }
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.86),
            value: uiState.selectedTab
        )
        .onAppear {
            if !filteredIDs.isEmpty, !preferences.showsFirstLaunchSetup {
                return
            }
        }
    }

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
                Task { await usage.refresh() }
            } label: {
                Image(systemName: AppSymbols.refresh)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlassChrome.textSecondary)
                    .symbolEffect(.rotate, isActive: usage.isRefreshing && !reduceMotion)
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
            .accessibilityLabel(usage.isRefreshing ? "Refreshing" : "Refresh")
        }
    }

    private var updatedSubtitle: String {
        if let updated = QuotaFormatting.updatedLabel(for: usage.lastSuccessfulRefresh) {
            return "Updated " + updated
        }
        return "Your usage at a glance"
    }

    private var refreshHelp: String {
        if usage.isRefreshing { return "Refresh" }
        if let updated = QuotaFormatting.updatedLabel(for: usage.lastSuccessfulRefresh) {
            return "Refresh (\(updated))"
        }
        return "Refresh"
    }

    private var offlineBanner: some View {
        Text("You’re offline. Showing last saved usage.")
            .font(.caption2.weight(.medium))
            .foregroundStyle(GlassChrome.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            }
            .accessibilityLabel("Offline. Showing last saved usage.")
    }

    private var firstLaunchIntro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Usage appears from apps already signed in on this Mac.")
                .font(.caption)
                .foregroundStyle(GlassChrome.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Continue") {
                preferences.completeFirstLaunch()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

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

    private var emptyProviderHint: String {
        guard case .provider(let id) = uiState.selectedTab else {
            return "This provider has no usage to show."
        }
        return ProviderLoginAction.hint(for: id)
    }

    private func copy(_ command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        copiedCommand = command
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            if copiedCommand == command { copiedCommand = nil }
        }
    }
}

private struct FooterScrim: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Rectangle().fill(Color(nsColor: .windowBackgroundColor))
        } else {
            Rectangle().fill(.thinMaterial)
        }
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
            isHovered = hovering
        }
    }
}
