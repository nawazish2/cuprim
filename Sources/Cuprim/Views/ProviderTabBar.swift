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

/// Compact icon-led selector for All plus every enabled provider.
struct ProviderTabBar: View {
    @Binding var selection: ProviderTab
    let available: [ProviderID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNS

    private var items: [(tab: ProviderTab, title: String, systemImage: String)] {
        [(.overview, "All", AppSymbols.overviewTab)]
            + available.map { (.provider($0), $0.displayName, $0.systemImage) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tab) { item in
                cell(item)
            }
        }
        .padding(2)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(0.55))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Providers")
    }

    private func cell(_ item: (tab: ProviderTab, title: String, systemImage: String)) -> some View {
        let selected = selection == item.tab
        return Button {
            guard item.tab != selection else { return }
            if reduceMotion {
                selection = item.tab
            } else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    selection = item.tab
                }
            }
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: 11, weight: selected ? .semibold : .medium))
                .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.58))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.background.opacity(0.92))
                            .shadow(color: .black.opacity(0.12), radius: 1.5, y: 0.5)
                            .matchedGeometryEffect(id: "tab-pill", in: selectionNS)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(item.title)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .keyboardShortcut(shortcut(for: item.tab), modifiers: [])
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
