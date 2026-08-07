import SwiftUI
import CuprimCore

/// Compact glass dashboard tokens — Liquid Glass shell, solid content cards.
enum GlassChrome {
    static let panelCorner: CGFloat = 14
    static let cardCorner: CGFloat = 14
    static let tabBarCorner: CGFloat = 11
    static let tabPillCorner: CGFloat = 10
    static let panelWidth: CGFloat = 300
    /// Tall enough for several providers + pinned footer.
    static let panelHeight: CGFloat = 420
    static let outerPad: CGFloat = 0
    static let inset: CGFloat = 12
    static let cardPad: CGFloat = 10
    static let cardGap: CGFloat = 10
    static let scrollBottomPad: CGFloat = 12
    static let sectionGap: CGFloat = 8
    static let meterHeight: CGFloat = 12
    static let providerIconSize: CGFloat = 22
    static let brandBlue = Color(red: 0.0, green: 0.451, blue: 0.922)

    // MARK: Type (3 levels)

    static let textPrimary = Color.primary.opacity(0.98)
    static let textSecondary = Color.primary.opacity(0.78)
    static let textTertiary = Color.primary.opacity(0.62)
    static let textTabIdle = Color.primary.opacity(0.60)
    static let textTabActive = Color.primary.opacity(0.98)

    static let panelScrimDark = Color.black.opacity(0.68)
    static let panelScrimLight = Color.white.opacity(0.86)
    static let footerScrimDark = Color.black.opacity(0.50)
    static let footerScrimLight = Color.white.opacity(0.72)
    /// Solid cards (not glass).
    static let cardFill = Color.primary.opacity(0.09)
    static let cardStroke = Color.primary.opacity(0.12)
    static let cardShadow = Color.black.opacity(0.22)
}

// MARK: - Surfaces

struct GlassPanelBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.panelCorner, style: .continuous)
        let scrim = colorScheme == .dark
            ? GlassChrome.panelScrimDark
            : GlassChrome.panelScrimLight

        content
            .background {
                shape.fill(scrim)
            }
            .glassEffect(.regular.interactive(), in: shape)
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.5)
            }
            .clipShape(shape)
    }
}

struct GlassCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: GlassChrome.cardCorner, style: .continuous)
                    .fill(GlassChrome.cardFill)
            }
    }
}

struct GlassTabBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.tabBarCorner, style: .continuous)
        content
            .background { shape.fill(Color.primary.opacity(0.07)) }
            .clipShape(shape)
    }
}

struct GlassTabPillBackground: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.tabPillCorner, style: .continuous)
        content
            .background { shape.fill(Color.primary.opacity(0.15)) }
            .clipShape(shape)
    }
}

struct GlassIconWell: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(GlassChrome.textPrimary)
            .frame(width: 20, height: 20)
    }
}

extension View {
    func agentGlassPanel() -> some View { modifier(GlassPanelBackground()) }
    func agentGlassCard() -> some View { modifier(GlassCardBackground()) }
    func agentGlassTabBar() -> some View { modifier(GlassTabBarBackground()) }
    func agentGlassTabPill() -> some View { modifier(GlassTabPillBackground()) }
    func agentGlassIconWell() -> some View { modifier(GlassIconWell()) }
}
