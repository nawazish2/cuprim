import AppKit
import SwiftUI
import CuprimCore

/// Monochrome brand mark; color controlled by `foreground`.
struct ProviderIconView: View {
    let id: ProviderID
    var size: CGFloat = 15
    var opticalScale: CGFloat = 1
    var foreground: Color = Color.primary.opacity(0.92)
    /// Force a specific SF Symbol instead of the brand asset. Grok's
    /// ring-and-diagonal mark reads as a "no entry" glyph at very small
    /// monochrome sizes (the tab bar) no matter how it's scaled — there's
    /// more context (name label, larger size) everywhere else it's used,
    /// so this only needs to be set at the tab bar's compact scale.
    var overrideSystemSymbol: String?

    var body: some View {
        Group {
            if let symbol = overrideSystemSymbol {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.85, weight: .semibold))
                    .foregroundStyle(foreground)
            } else if let image = Self.templateImage(for: id) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(foreground)
            } else {
                Image(systemName: id.systemImage)
                    .font(.system(size: size * 0.85, weight: .semibold))
                    .foregroundStyle(foreground)
            }
        }
        .frame(width: size * opticalScale, height: size * opticalScale)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    static func templateImage(for id: ProviderID) -> NSImage? {
        let name = id.rawValue
        guard let image = AppResources.image(name: name, subdirectory: "ProviderIcons") else {
            return nil
        }
        image.isTemplate = true
        image.size = NSSize(width: 32, height: 32)
        return image
    }
}

/// Soft circular well so provider logos sit consistently.
struct ProviderIconWell: View {
    let id: ProviderID
    var size: CGFloat = 22

    private var well: CGFloat { max(30, size + 10) }

    var body: some View {
        ProviderIconView(id: id, size: size, foreground: GlassChrome.textPrimary)
            .frame(width: well, height: well)
            .background {
                Circle()
                    .fill(Color.primary.opacity(0.11))
            }
    }
}

struct PlanBadgeView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(GlassChrome.textTertiary.opacity(0.95))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.08))
            }
    }
}

/// Monochrome cup mark for panel header (template-style).
struct CupBrandMark: View {
    var size: CGFloat = 14
    var foreground: Color = .secondary

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let ox = (canvasSize.width - s) / 2
            let oy = (canvasSize.height - s) / 2

            // Lid
            var lid = Path()
            lid.addRoundedRect(
                in: CGRect(x: ox + s * 0.12, y: oy + s * 0.14, width: s * 0.76, height: s * 0.14),
                cornerSize: CGSize(width: s * 0.04, height: s * 0.04)
            )
            context.fill(lid, with: .color(foreground))

            // Cup body
            var cup = Path()
            cup.move(to: CGPoint(x: ox + s * 0.22, y: oy + s * 0.30))
            cup.addLine(to: CGPoint(x: ox + s * 0.28, y: oy + s * 0.82))
            cup.addQuadCurve(
                to: CGPoint(x: ox + s * 0.72, y: oy + s * 0.82),
                control: CGPoint(x: ox + s * 0.50, y: oy + s * 0.90)
            )
            cup.addLine(to: CGPoint(x: ox + s * 0.78, y: oy + s * 0.30))
            cup.closeSubpath()
            context.fill(cup, with: .color(foreground))

            // Handle
            var handle = Path()
            handle.addArc(
                center: CGPoint(x: ox + s * 0.82, y: oy + s * 0.50),
                radius: s * 0.14,
                startAngle: .degrees(-70),
                endAngle: .degrees(70),
                clockwise: false
            )
            context.stroke(
                handle,
                with: .color(foreground),
                style: StrokeStyle(lineWidth: s * 0.09, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
