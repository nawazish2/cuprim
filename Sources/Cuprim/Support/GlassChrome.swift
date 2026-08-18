import SwiftUI
import CuprimCore

/// Compact dashboard tokens — one native Liquid Glass shell, quiet grouped rows.
enum GlassChrome {
    static let panelCorner: CGFloat = 18
    static let cardCorner: CGFloat = 12
    static let tabBarCorner: CGFloat = 11
    static let tabPillCorner: CGFloat = 10
    static let panelWidth: CGFloat = 300
    static let panelHeight: CGFloat = 420
    static let outerPad: CGFloat = 0
    static let inset: CGFloat = 12
    static let cardPad: CGFloat = 11
    static let cardGap: CGFloat = 8
    static let scrollBottomPad: CGFloat = 12
    static let sectionGap: CGFloat = 8
    static let meterHeight: CGFloat = 8
    static let providerIconSize: CGFloat = 18
    static let brandBlue = Color(red: 0.0, green: 0.451, blue: 0.922)

    static let textPrimary = Color.primary.opacity(0.98)
    static let textSecondary = Color.primary.opacity(0.78)
    static let textTertiary = Color.primary.opacity(0.62)
    static let textTabIdle = Color.primary.opacity(0.60)
    static let textTabActive = Color.primary.opacity(0.98)

    static let panelScrimDark = Color.black.opacity(0.28)
    static let panelScrimLight = Color.white.opacity(0.58)
    static let cardFill = Color.primary.opacity(0.045)
    static let cardStroke = Color.primary.opacity(0.10)
}

struct GlassPanelBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.panelCorner, style: .continuous)
        let scrim = colorScheme == .dark
            ? GlassChrome.panelScrimDark
            : GlassChrome.panelScrimLight

        content
            .background {
                shape.fill(reduceTransparency ? Color(nsColor: .windowBackgroundColor) : scrim)
            }
            .modifier(OptionalGlassEffect(enabled: !reduceTransparency, shape: shape))
            .overlay {
                shape.strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.5)
            }
            .clipShape(shape)
    }
}

private struct OptionalGlassEffect<S: Shape>: ViewModifier {
    let enabled: Bool
    let shape: S

    func body(content: Content) -> some View {
        if enabled {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content
        }
    }
}

struct GroupedCardBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: GlassChrome.cardCorner, style: .continuous)
        let fill = contrast == .increased
            ? Color.primary.opacity(0.08)
            : GlassChrome.cardFill
        content
            .background {
                shape.fill(reduceTransparency ? Color(nsColor: .controlBackgroundColor) : fill)
            }
            .overlay {
                shape.strokeBorder(GlassChrome.cardStroke, lineWidth: contrast == .increased ? 1 : 0.5)
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
    func cuprimGlassPanel() -> some View { modifier(GlassPanelBackground()) }
    func cuprimGroupedCard() -> some View { modifier(GroupedCardBackground()) }
    func cuprimGlassTabBar() -> some View { modifier(GlassTabBarBackground()) }
    func cuprimGlassTabPill() -> some View { modifier(GlassTabPillBackground()) }
    func cuprimGlassIconWell() -> some View { modifier(GlassIconWell()) }
}