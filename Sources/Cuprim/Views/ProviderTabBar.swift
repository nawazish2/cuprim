import SwiftUI
import CuprimCore

enum ProviderTab: Hashable, Identifiable {
    case overview
    case provider(ProviderID)

    var id: String {
        switch self {
        case .overview: "overview"
        case .provider(let id): id.rawValue
        }
    }
}

/// Native-feeling segmented chips — soft track, rounded active pill.
struct ProviderTabBar: View {
    @Binding var selection: ProviderTab
    let available: [ProviderID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Prefer system segmented when All + providers fit (~4 segments).
    private var useNativeSegmented: Bool {
        available.count <= 3
    }

    private var selectionSpring: Animation? {
        reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.86)
    }

    var body: some View {
        Group {
            if useNativeSegmented {
                nativePicker
            } else {
                scrollingChips
            }
        }
        .animation(selectionSpring, value: selection)
    }

    private var nativePicker: some View {
        Picker("", selection: $selection) {
            Text("All").tag(ProviderTab.overview)
            ForEach(available) { id in
                Text(shortName(id)).tag(ProviderTab.provider(id))
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.small)
    }

    private var scrollingChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                chip(tab: .overview, title: "All")
                ForEach(available) { id in
                    chip(tab: .provider(id), title: shortName(id))
                }
            }
            .padding(3)
        }
        .agentGlassTabBar()
    }

    private func chip(tab: ProviderTab, title: String) -> some View {
        let selected = selection == tab

        return Button {
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(selectionSpring) {
                    selection = tab
                }
            }
        } label: {
            Text(title)
                .font(.caption.weight(selected ? .semibold : .medium))
                .foregroundStyle(selected ? GlassChrome.textTabActive : GlassChrome.textTabIdle)
                .lineLimit(1)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: GlassChrome.tabPillCorner, style: .continuous)
                            .fill(Color.primary.opacity(0.15))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func shortName(_ id: ProviderID) -> String {
        switch id {
        case .claude: "Claude"
        case .codex: "Codex"
        case .cursor: "Cursor"
        case .grok: "Grok"
        }
    }
}
