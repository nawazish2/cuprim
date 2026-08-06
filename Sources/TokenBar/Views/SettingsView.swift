import AppKit
import SwiftUI
import TokenBarCore

/// Native-feeling preferences for the SwiftUI Settings scene.
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsGroup(title: "Providers") {
                    VStack(spacing: 0) {
                        ForEach(Array(preferences.orderedProviders.enumerated()), id: \.element) { index, id in
                            providerRow(id: id, index: index)
                            if index < preferences.orderedProviders.count - 1 {
                                Divider()
                                    .padding(.leading, 34)
                            }
                        }
                    }
                } footer: {
                    Text("Use the arrows to change order in the menu and dashboard.")
                }

                settingsGroup(title: "Display") {
                    VStack(spacing: 0) {
                        toggleRow("Show used %", isOn: $preferences.showUsedPercent)
                        Divider().padding(.leading, 12)
                        toggleRow("Absolute reset times", isOn: $preferences.absoluteResetTimes)
                        Divider().padding(.leading, 12)
                        toggleRow("Hide logged-out providers", isOn: $preferences.hideLoggedOutProviders)
                    }
                }

                settingsGroup(title: "General") {
                    VStack(alignment: .leading, spacing: 0) {
                        toggleRow("Launch at login", isOn: launchAtLoginBinding)
                            .disabled(preferences.launchAtLoginState == .unavailable)

                        if preferences.launchAtLoginState == .requiresApproval {
                            Divider().padding(.leading, 12)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Allow TokenBar in System Settings → General → Login Items.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button("Open Login Items…") {
                                    openLoginItemsSettings()
                                }
                                .controlSize(.small)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        } else if preferences.launchAtLoginState == .unavailable {
                            Divider().padding(.leading, 12)
                            Text("Needs a Developer ID–signed build (ad-hoc / unsigned apps can’t register login items).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }

                        if let error = preferences.launchAtLoginError {
                            Divider().padding(.leading, 12)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }

                        Divider().padding(.leading, 12)
                        infoRow("Auto-refresh", value: "Every 2 min")
                    }
                }

                settingsGroup(title: "About") {
                    VStack(spacing: 0) {
                        infoRow("Version", value: OpenSourceInfo.versionString)
                        Divider().padding(.leading, 12)
                        infoRow("Requires", value: "macOS 26 · Apple Silicon")
                        Divider().padding(.leading, 12)
                        buttonRow("About TokenBar…") {
                            AboutWindowController.show()
                        }
                        Divider().padding(.leading, 12)
                        buttonRow("Check for Updates…") {
                            OpenSourceInfo.openReleases()
                        }
                        Divider().padding(.leading, 12)
                        linkRow("GitHub", url: OpenSourceInfo.repositoryURL)
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            preferences.refreshLaunchAtLoginState()
        }
    }

    // MARK: - Rows

    private func providerRow(id: ProviderID, index: Int) -> some View {
        HStack(spacing: 10) {
            ProviderIconView(id: id, size: 15)
            Text(id.displayName)
                .font(.body)
            Spacer(minLength: 8)
            Toggle(
                "Enabled",
                isOn: Binding(
                    get: { preferences.isEnabled(id) },
                    set: { preferences.setEnabled(id, $0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            HStack(spacing: 2) {
                Button {
                    preferences.moveProvider(id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(index == 0)
                .help("Move up")

                Button {
                    preferences.moveProvider(id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(index >= preferences.orderedProviders.count - 1)
                .help("Move down")
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(.switch)
            .controlSize(.small)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func buttonRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
    }

    private func linkRow(_ title: String, url: URL) -> some View {
        Link(title, destination: url)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
    }

    // MARK: - Chrome

    private func settingsGroup<Content: View, Footer: View>(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            content()
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                )

            footer()
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
        }
    }

    private func settingsGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        settingsGroup(title: title, content: content, footer: { EmptyView() })
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
