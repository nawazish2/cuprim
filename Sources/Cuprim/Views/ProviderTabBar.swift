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

/// Native segmented row for the original set, plus a quiet capsule rail for extras.
struct ProviderTabBar: View {
    @Binding var selection: ProviderTab
    let available: [ProviderID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNS

    private var primary: [ProviderID] {
        available.filter { $0 != .antigravity }
    }

    private var extras: [ProviderID] {
        available.filter { $0 == .antigravity }
    }

    private var primaryTabs: [(tab: ProviderTab, title: String)] {
        [(.overview, "All")] + primary.map { (.provider($0), $0.displayName) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            primaryRow

            if !extras.isEmpty {
                extraRail
            }
        }
    }

    private var primaryRow: some View {
        HStack(spacing: 0) {
            ForEach(primaryTabs, id: \.tab) { item in
                primaryCell(item)
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
    }

    private func primaryCell(_ item: (tab: ProviderTab, title: String)) -> some View {
        let selected = selection == item.tab
        return Button {
            select(item.tab)
        } label: {
            Text(item.title)
                .font(.system(size: 11, weight: selected ? .semibold : .medium))
                .tracking(-0.15)
                .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.background.opacity(0.92))
                            .shadow(color: .black.opacity(0.12), radius: 1.5, y: 0.5)
                            .matchedGeometryEffect(id: "primary-pill", in: selectionNS)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var extraRail: some View {
        HStack(spacing: 6) {
            ForEach(extras) { id in
                extraCapsule(id)
            }
        }
    }

    private func extraCapsule(_ id: ProviderID) -> some View {
        let tab = ProviderTab.provider(id)
        let selected = selection == tab
        return Button {
            select(tab)
        } label: {
            HStack(spacing: 5) {
                ProviderIconView(
                    id: id,
                    size: 10,
                    foreground: selected ? Color.primary : Color.primary.opacity(0.62)
                )
                Text(id.displayName)
                    .font(.system(size: 11, weight: selected ? .semibold : .medium))
                    .tracking(-0.2)
                    .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.62))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(selected ? Color.primary.opacity(0.14) : Color.primary.opacity(0.055))
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        Color.primary.opacity(selected ? 0.16 : 0.07),
                        lineWidth: 0.5
                    )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(selected && !reduceMotion ? 1 : 0.99)
        .accessibilityLabel(id.displayName)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func select(_ tab: ProviderTab) {
        guard tab != selection else { return }
        if reduceMotion {
            selection = tab
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                selection = tab
            }
        }
    }
}
