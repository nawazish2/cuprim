import SwiftUI
import CuprimCore

/// Compact ChatGPT-style menu panel tokens.
enum GlassChrome {
    static let panelCorner: CGFloat = 14
    static let cardCorner: CGFloat = 10
    static let tabBarCorner: CGFloat = 8
    static let tabPillCorner: CGFloat = 6
    static let panelWidth: CGFloat = 300
    /// Tall enough for several providers + pinned footer.
    static let panelHeight: CGFloat = 420
    static let outerPad: CGFloat = 0
    static let inset: CGFloat = 12
}

// MARK: - Surfaces

/// Single outer shell — only glass layer (menu popover look).
struct GlassPanelBackground: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.panelCorner, style: .continuous)
        content
            .glassEffect(.regular.interactive(), in: shape)
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
            .clipShape(shape)
    }
}

/// Unused nested cards — kept for compatibility; prefer flat list.
struct GlassCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: GlassChrome.cardCorner, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            }
    }
}

struct GlassTabBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.tabBarCorner, style: .continuous)
        content
            .background { shape.fill(Color.primary.opacity(0.06)) }
            .clipShape(shape)
    }
}

struct GlassTabPillBackground: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.tabPillCorner, style: .continuous)
        content
            .background { shape.fill(Color.primary.opacity(0.12)) }
            .clipShape(shape)
    }
}

struct GlassIconWell: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary.opacity(0.85))
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
