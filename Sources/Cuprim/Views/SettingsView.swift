import AppKit
import SwiftUI
import CuprimCore

/// Compact, System Settings–style preferences.
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore

    private let rowH: CGFloat = 34
    private let padX: CGFloat = 12

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                group("Providers") {
                    ForEach(Array(preferences.orderedProviders.enumerated()), id: \.element) { index, id in
                        providerRow(id: id, index: index)
                        if index < preferences.orderedProviders.count - 1 {
                            hairline
                        }
                    }
                } footer: {
                    Text("Arrows reorder the menu and dashboard.")
                }

                group("Display") {
                    labeledToggle("Show used %", isOn: $preferences.showUsedPercent)
                    hairline
                    labeledToggle("Absolute reset times", isOn: $preferences.absoluteResetTimes)
                    hairline
                    labeledToggle("Hide logged-out providers", isOn: $preferences.hideLoggedOutProviders)
                }

                group("Quota Horizon") {
                    labeledToggle("Local alerts", isOn: $preferences.horizonAlertsEnabled)
                } footer: {
                    Text("Alerts are off by default and use only local usage history.")
                }

                group("General") {
                    labeledToggle("Launch at login", isOn: launchAtLoginBinding)
                        .disabled(preferences.launchAtLoginState == .unavailable)
                    hairline
                    refreshPicker

                    if preferences.launchAtLoginState == .requiresApproval {
                        hairline
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Allow Cuprim under Login Items in System Settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Open Login Items…") { openLoginItemsSettings() }
                                .controlSize(.small)
                        }
                        .padding(.horizontal, padX)
                        .padding(.vertical, 8)
                    }
                } footer: {
                    if preferences.launchAtLoginState == .unavailable {
                        Text("Login items need a Developer ID–signed build.")
                    } else if let error = preferences.launchAtLoginError {
                        Text(error).foregroundStyle(.red)
                    } else {
                        EmptyView()
                    }
                }

                group("About") {
                    labeledValue("Version", value: OpenSourceInfo.versionString)
                    hairline
                    labeledValue("Requires", value: "macOS 26 · Apple Silicon")
                    hairline
                    actionRow("About Cuprim…") { AboutWindowController.show() }
                    hairline
                    actionRow("Check for Updates…") { OpenSourceInfo.checkForUpdates() }
                    hairline
                    Link("GitHub", destination: OpenSourceInfo.repositoryURL)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, padX)
                        .frame(height: rowH)
                }
            }
            .padding(16)
        }
        .frame(width: 380, height: 480)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .onAppear { preferences.refreshLaunchAtLoginState() }
    }

    // MARK: - Rows

    private func providerRow(id: ProviderID, index: Int) -> some View {
        HStack(spacing: 8) {
            ProviderIconView(id: id, size: 14)
            Text(id.displayName)
                .font(.body)
            Spacer(minLength: 8)

            HStack(spacing: 0) {
                reorderButton(systemName: "chevron.up", enabled: index > 0) {
                    preferences.moveProvider(id, direction: -1)
                }
                reorderButton(
                    systemName: "chevron.down",
                    enabled: index < preferences.orderedProviders.count - 1
                ) {
                    preferences.moveProvider(id, direction: 1)
                }
            }

            Toggle(
                "",
                isOn: Binding(
                    get: { preferences.isEnabled(id) },
                    set: { preferences.setEnabled(id, $0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
        }
        .padding(.horizontal, padX)
        .frame(height: rowH)
    }

    private func reorderButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(enabled ? Color.secondary : Color.secondary.opacity(0.25))
        .disabled(!enabled)
    }

    private func labeledToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(.horizontal, padX)
        .frame(height: rowH)
    }

    private func labeledValue(_ title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.body)
            Spacer(minLength: 8)
            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, padX)
        .frame(height: rowH)
    }

    private var refreshPicker: some View {
        HStack(spacing: 8) {
            Text("Auto-refresh")
                .font(.body)
            Spacer(minLength: 8)
            Picker("Auto-refresh", selection: $preferences.refreshMinutes) {
                ForEach([1, 2, 5, 10, 15, 30], id: \.self) { minutes in
                    Text("Every \(minutes) min").tag(minutes)
                }
            }
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(.horizontal, padX)
        .frame(height: rowH)
    }

    private func actionRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, padX)
        .frame(height: rowH)
    }

    private var hairline: some View {
        Divider()
            .padding(.leading, padX)
    }

    // MARK: - Group chrome

    private func group<Content: View, Footer: View>(
        _ title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.4)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            footer()
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 2)
        }
    }

    private func group<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        group(title, content: content, footer: { EmptyView() })
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
