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

/// One segmented control: original providers on the first row, extras on the next.
struct ProviderTabBar: View {
    @Binding var selection: ProviderTab
    let available: [ProviderID]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var selectionNS

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 5)

    private var items: [(tab: ProviderTab, title: String)] {
        let primary = available.filter { $0 != .antigravity }
        let extras = available.filter { $0 == .antigravity }
        return [(.overview, "All")]
            + primary.map { (.provider($0), $0.displayName) }
            + extras.map { (.provider($0), $0.displayName) }
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
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
    }

    private func cell(_ item: (tab: ProviderTab, title: String)) -> some View {
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
            Text(item.title)
                .font(.system(size: 11, weight: selected ? .semibold : .medium))
                .tracking(-0.15)
                .foregroundStyle(selected ? Color.primary : Color.primary.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
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
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
