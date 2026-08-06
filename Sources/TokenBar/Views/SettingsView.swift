import AppKit
import SwiftUI
import TokenBarCore

/// Compact native preferences — single Form (no broken split sidebar).
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore

    var body: some View {
        Form {
            Section {
                ForEach(Array(preferences.orderedProviders.enumerated()), id: \.element) { index, id in
                    HStack(spacing: 8) {
                        ProviderIconView(id: id, size: 13)

                        Text(id.displayName)

                        Spacer(minLength: 4)

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

                        Button {
                            preferences.moveProvider(id, direction: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderless)
                        .disabled(index == 0)
                        .help("Move up")

                        Button {
                            preferences.moveProvider(id, direction: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderless)
                        .disabled(index >= preferences.orderedProviders.count - 1)
                        .help("Move down")
                    }
                }
            } header: {
                Text("Providers")
            } footer: {
                Text("Use ▲ ▼ to reorder.")
            }

            Section {
                Toggle("Show used %", isOn: $preferences.showUsedPercent)
                Toggle("Absolute reset times", isOn: $preferences.absoluteResetTimes)
                Toggle("Hide logged-out providers", isOn: $preferences.hideLoggedOutProviders)
            } header: {
                Text("Display")
            }

            Section {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
                    .disabled(preferences.launchAtLoginState == .unavailable)
                if preferences.launchAtLoginState == .requiresApproval {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Approval is required in System Settings before TokenBar can launch at login.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Open Login Items Settings") {
                            openLoginItemsSettings()
                        }
                        .controlSize(.small)
                    }
                } else if preferences.launchAtLoginState == .unavailable {
                    Text("Launch at login is unavailable for this app build.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let error = preferences.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                LabeledContent("Auto-refresh", value: "Every 2 min")
            } header: {
                Text("General")
            }

            Section {
                LabeledContent("Requires", value: "macOS 26 · Apple Silicon")
                Button("About TokenBar…") {
                    AboutWindowController.show()
                }
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 420)
        .onAppear {
            preferences.refreshLaunchAtLoginState()
        }
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
