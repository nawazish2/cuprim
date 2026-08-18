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

/// Compact icon selector: All plus every enabled provider’s brand mark.
struct ProviderTabBar: View {
    @Binding var selection: ProviderTab
    let available: [ProviderID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNS

    var body: some View {
        HStack(spacing: 1) {
            tabButton(tab: .overview, title: "All") {
                Image(systemName: AppSymbols.app)
                    .font(.system(size: 12, weight: selection == .overview ? .semibold : .medium))
                    .symbolRenderingMode(.hierarchical)
            }
            ForEach(available, id: \.self) { id in
                tabButton(tab: .provider(id), title: id.displayName) {
                    ProviderIconView(
                        id: id,
                        size: 13,
                        foreground: selection == .provider(id)
                            ? GlassChrome.textTabActive
                            : GlassChrome.textTabIdle
                    )
                }
            }
        }
        .padding(3)
        .cuprimGlassTabBar()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Providers")
    }

    private func tabButton<Icon: View>(
        tab: ProviderTab,
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        let selected = selection == tab
        return Button {
            guard tab != selection else { return }
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    selection = tab
                }
            }
        } label: {
            icon()
                .foregroundStyle(selected ? GlassChrome.textTabActive : GlassChrome.textTabIdle)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: GlassChrome.tabPillCorner, style: .continuous)
                            .fill(Color.primary.opacity(0.14))
                            .matchedGeometryEffect(id: "tab-pill", in: selectionNS)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .keyboardShortcut(shortcut(for: tab), modifiers: [])
    }

    private func shortcut(for tab: ProviderTab) -> KeyEquivalent {
        switch tab {
        case .overview: "0"
        case .provider(let id):
            switch id {
            case .claude: "1"
            case .codex: "2"
            case .cursor: "3"
            case .grok: "4"
            case .antigravity: "5"
            }
        }
    }
}
