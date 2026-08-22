import SwiftUI
import CuprimCore

/// Compact dashboard tokens — one native Liquid Glass shell, quiet grouped rows.
enum GlassChrome {
    // 4pt-based spacing/radius scale shared across the panel.
    static let panelCorner: CGFloat = 14
    static let cardCorner: CGFloat = 12
    static let panelWidth: CGFloat = 288
    static let panelHeight: CGFloat = 380
    static let outerPad: CGFloat = 0
    static let inset: CGFloat = 10
    static let cardPad: CGFloat = 10
    static let cardGap: CGFloat = 6
    static let scrollBottomPad: CGFloat = 10
    static let meterHeight: CGFloat = 6
    static let providerIconSize: CGFloat = 16

    /// Meter severity colors, keyed to the same thresholds as
    /// `Formatting.meterColor`. Single source of truth for usage-state color.
    static let usageBlue = Color(red: 0.24, green: 0.55, blue: 0.98)
    static let usageAmber = Color(red: 0.96, green: 0.68, blue: 0.22)
    static let usageOrange = Color(red: 0.95, green: 0.43, blue: 0.20)
    static let usageRed = Color(red: 0.96, green: 0.28, blue: 0.32)

    static let textPrimary = Color.primary.opacity(0.98)
    static let textSecondary = Color.primary.opacity(0.78)
    static let textTertiary = Color.primary.opacity(0.62)
    static let textTabIdle = Color.primary.opacity(0.68)
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

extension View {
    func cuprimGlassPanel() -> some View { modifier(GlassPanelBackground()) }
    func cuprimGroupedCard() -> some View { modifier(GroupedCardBackground()) }
}