import AppKit
import SwiftUI
import CuprimCore

/// Compact grouped Settings — native type, tight rows, no Form air.
struct SettingsView: View {
    @Bindable var preferences: PreferencesStore

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
                            isOn: enabledBinding(for: id)
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                    }
                    .onMove { source, destination in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            preferences.moveProviders(from: source, to: destination)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: providerRowHeight * CGFloat(preferences.orderedProviders.count) + 8)
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: preferences.orderedProviders)
            }

            group("Display") {
                toggle("Show used percent", isOn: $preferences.showUsedPercent)
                divider
                toggle("Absolute reset times", isOn: $preferences.absoluteResetTimes)
                divider
                toggle("Hide signed-out providers", isOn: $preferences.hideLoggedOutProviders)
            }

            group("General", footer: generalFooterText) {
                toggle("Launch at login", isOn: launchAtLoginBinding)
                    .disabled(preferences.launchAtLoginState == .unavailable)
                divider
                refreshRow
                divider
                toggle("Local alerts", isOn: $preferences.horizonAlertsEnabled)

                if preferences.launchAtLoginState == .requiresApproval {
                    divider
                    Button("Open Login Items…") { openLoginItemsSettings() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                        .font(.callout)
                        .padding(.horizontal, inset)
                        .frame(height: rowHeight, alignment: .leading)
                }
            }

            group("About", footer: "macOS 26 · Apple Silicon") {
                infoRow("Version", shortVersion)
                divider
                HStack(spacing: 14) {
                    Button("About") { AboutWindowController.show() }
                    Button("Updates") { OpenSourceInfo.checkForUpdates() }
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
        .onAppear { preferences.refreshLaunchAtLoginState() }
    }

    // MARK: - Rows

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

    // MARK: - Group

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

    // MARK: - Bindings

    private var shortVersion: String {
        OpenSourceInfo.versionString.replacingOccurrences(of: "Version ", with: "")
    }

    private var generalFooterText: String? {
        if preferences.launchAtLoginState == .unavailable {
            return "Login items need a Developer ID–signed build."
        }
        if let error = preferences.launchAtLoginError {
            return error
        }
        return "Alerts stay on this Mac."
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .opacity(isHovered ? 0.9 : 0.35)
                .offset(x: isHovered ? 0 : -2)
                .accessibilityHidden(true)

            ProviderIconView(id: id, size: 13, foreground: isOn ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(isHovered ? 0.12 : 0.08))
                }
                .scaleEffect(isOn ? 1 : 0.94)

            Text(id.displayName)
                .font(.callout.weight(.medium))
                .foregroundStyle(isOn ? .primary : .secondary)

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 4)
        .frame(height: 32)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
        }
        .opacity(isOn ? 1 : 0.72)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.84), value: isOn)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(id.displayName)
    }
}
