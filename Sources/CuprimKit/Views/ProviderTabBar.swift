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
    @Environment(\.colorSchemeContrast) private var contrast
    @Namespace private var selectionNS

    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .overview, title: "All") {
                Image(systemName: AppSymbols.app)
                    .font(.system(size: 13, weight: selection == .overview ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 16, height: 16)
            }
            ForEach(available, id: \.self) { id in
                tabButton(tab: .provider(id), title: id.displayName) {
                    ProviderIconView(
                        id: id,
                        size: 16,
                        opticalScale: id.tabMarkScale,
                        foreground: selection == .provider(id)
                            ? GlassChrome.textTabActive
                            : GlassChrome.textTabIdle,
                        // Distinct from Claude's actual mark, which is
                        // itself a sparkle/asterisk burst — reusing
                        // ProviderID.systemImage ("sparkles") here would
                        // trade one collision for another.
                        overrideSystemSymbol: id == .grok ? "bolt.fill" : nil
                    )
                }
            }
        }
        .padding(3)
        .background {
            ZStack {
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(contrast == .increased ? 0.10 : 0.055))
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(contrast == .increased ? 0.18 : 0.08), lineWidth: 0.5)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Providers")
    }

    private func tabButton<Icon: View>(
        tab: ProviderTab,
        title: String,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        TabSegment(
            title: title,
            selected: selection == tab,
            reduceMotion: reduceMotion,
            contrast: contrast,
            namespace: selectionNS,
            shortcut: shortcut(for: tab),
            icon: icon(),
            action: {
                guard tab != selection else { return }
                if reduceMotion {
                    selection = tab
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        selection = tab
                    }
                }
            }
        )
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
            }
        }
    }
}

private struct TabSegment<Icon: View>: View {
    let title: String
    let selected: Bool
    let reduceMotion: Bool
    let contrast: ColorSchemeContrast
    let namespace: Namespace.ID
    let shortcut: KeyEquivalent
    let icon: Icon
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            icon
                .foregroundStyle(selected ? GlassChrome.textTabActive : GlassChrome.textTabIdle)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background {
                    if selected {
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(contrast == .increased ? 0.22 : 0.16))
                            .shadow(color: Color.black.opacity(reduceMotion ? 0 : 0.18), radius: 1, y: 0.5)
                            .matchedGeometryEffect(id: "tab-pill", in: namespace)
                    } else if hovered {
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    }
                }
                .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .keyboardShortcut(shortcut, modifiers: [])
        .onHover { hovered = $0 }
    }
}

private extension ProviderID {
    /// Keep brand marks at the same optical size in a 16pt well.
    var tabMarkScale: CGFloat {
        switch self {
        case .claude: 0.92
        case .codex: 0.84
        case .cursor: 1.02
        // Grok uses an SF Symbol override in the tab bar (see
        // `overrideSystemSymbol` above), rendered at a slightly smaller
        // scale to match the other glyphs' optical weight.
        case .grok: 0.95
        }
    }
}
