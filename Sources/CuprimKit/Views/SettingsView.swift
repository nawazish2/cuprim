import AppKit
import SwiftUI
import CuprimCore

/// Compact grouped Settings — Providers, Display, Refresh and alerts, About.
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore
    var usage: UsageStore?
    var notifications: NotificationCoordinator?

    private let rowHeight: CGFloat = 28
    private let providerRowHeight: CGFloat = 36
    private let inset: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            group("Providers", footer: "Drag a row to reorder.") {
                List {
                    ForEach(preferences.orderedProviders) { id in
                        ProviderSettingsRow(
                            id: id,
                            isOn: enabledBinding(for: id),
                            status: usage?.presentation(for: id)
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove { source, destination in
                        preferences.moveProviders(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: providerRowHeight * CGFloat(preferences.orderedProviders.count) + 8)
            }

            group("Display") {
                toggle("Show used percent", isOn: $preferences.showUsedPercent)
                divider
                toggle("Absolute reset times", isOn: $preferences.absoluteResetTimes)
                divider
                toggle("Hide signed-out providers", isOn: $preferences.hideLoggedOutProviders)
            }

            group("Refresh and alerts", footer: alertsFooter) {
                toggle("Launch at login", isOn: launchAtLoginBinding)
                    .disabled(preferences.launchAtLoginState == .unavailable)
                divider
                refreshRow
                divider
                toggle("Low-quota alerts", isOn: $preferences.lowQuotaAlertsEnabled)

                if preferences.launchAtLoginState == .requiresApproval {
                    divider
                    Button("Open Login Items…") { openLoginItemsSettings() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                        .font(.callout)
                        .padding(.horizontal, inset)
                        .frame(height: rowHeight, alignment: .leading)
                }

                if preferences.lowQuotaAlertsEnabled, notifications?.permission == .denied {
                    divider
                    Button("Open Notification Settings…") {
                        notifications?.openSystemSettings()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .font(.callout)
                    .padding(.horizontal, inset)
                    .frame(height: rowHeight, alignment: .leading)
                }
            }

            group("About and updates", footer: "Private · No telemetry · MIT") {
                infoRow("Version", shortVersion)
                divider
                HStack(spacing: 14) {
                    Button("About") { AboutWindowController.show() }
                    Button("Check for Updates…") { OpenSourceInfo.checkForUpdates() }
                    Link("GitHub", destination: OpenSourceInfo.repositoryURL)
                    Spacer(minLength: 0)
                }
                .font(.callout)
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .padding(.horizontal, inset)
                .frame(height: rowHeight)
            }
        }
        .padding(14)
        .frame(width: 360, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            preferences.refreshLaunchAtLoginState()
            Task { await notifications?.refreshPermission() }
        }
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, inset)
        .frame(maxWidth: .infinity, minHeight: rowHeight)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.callout)
            Spacer(minLength: 8)
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, inset)
        .frame(maxWidth: .infinity, minHeight: rowHeight)
    }

    private var refreshRow: some View {
        HStack {
            Text("Auto-refresh")
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("Auto-refresh", selection: $preferences.refreshMinutes) {
                ForEach([1, 2, 5, 10, 15, 30], id: \.self) { minutes in
                    Text(minutes == 1 ? "Every minute" : "Every \(minutes) min")
                        .tag(minutes)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
        }
        .padding(.horizontal, inset)
        .frame(maxWidth: .infinity, minHeight: rowHeight)
    }

    private var divider: some View {
        Divider()
            .padding(.leading, inset)
    }

    private func group<Content: View>(
        _ title: String,
        footer: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.leading, 2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var shortVersion: String {
        OpenSourceInfo.versionString.replacingOccurrences(of: "Version ", with: "")
    }

    private var alertsFooter: String? {
        if preferences.launchAtLoginState == .unavailable {
            return "Launch at login needs a signed app. Alerts stay on this Mac."
        }
        if let error = preferences.launchAtLoginError {
            return error
        }
        if preferences.launchAtLoginState == .requiresApproval {
            return "macOS still needs approval in Login Items."
        }
        return "Alerts stay on this Mac. They fire at 20% and 5% remaining."
    }

    private func enabledBinding(for id: ProviderID) -> Binding<Bool> {
        Binding(
            get: { preferences.isEnabled(id) },
            set: { preferences.setEnabled(id, $0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { preferences.launchAtLogin },
            set: { preferences.launchAtLogin = $0 }
        )
    }

    private func openLoginItemsSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct ProviderSettingsRow: View {
    let id: ProviderID
    @Binding var isOn: Bool
    var status: ProviderPresentation?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            ProviderIconView(id: id, size: 13, foreground: isOn ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(id.displayName)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(isOn ? .primary : .secondary)
                if let caption = connectionCaption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 4)
        .frame(height: 32)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(id.displayName)
    }

    private var connectionCaption: String? {
        guard isOn, let status else { return nil }
        switch status {
        case .ready: return "Connected"
        case .stale: return "Saved usage"
        case .signedOut(let kind):
            return kind == .sessionExpired ? "Session expired" : "Not signed in"
        case .failed(let kind, _): return kind.userMessage
        case .loading: return "Checking"
        }
    }
}
