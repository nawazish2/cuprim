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

/// Compact text tabs — clean menu density, not tall icon grid.
struct ProviderTabBar: View {
    @Binding var selection: ProviderTab
    let available: [ProviderID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            chip(tab: .overview, title: "All")

            ForEach(available) { id in
                chip(tab: .provider(id), title: shortName(id))
            }
        }
        .padding(3)
        .agentGlassTabBar()
    }

    private func chip(tab: ProviderTab, title: String) -> some View {
        let selected = selection == tab

        return Button {
            if reduceMotion {
                selection = tab
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    selection = tab
                }
            }
        } label: {
            Text(title)
                .font(.caption.weight(selected ? .semibold : .medium))
                .foregroundStyle(selected ? Color.primary.opacity(0.95) : Color.primary.opacity(0.42))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: GlassChrome.tabPillCorner, style: .continuous)
                            .fill(Color.primary.opacity(0.12))
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
