import AppKit
import SwiftUI
import TokenBarCore

/// Monochrome brand mark; color controlled by `foreground`.
struct ProviderIconView: View {
    let id: ProviderID
    var size: CGFloat = 15
    var foreground: Color = Color.primary.opacity(0.92)

    var body: some View {
        Group {
            if let image = Self.templateImage(for: id) {
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

struct PlanBadgeView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}
