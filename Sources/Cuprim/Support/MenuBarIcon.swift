import AppKit
import Foundation
import CuprimCore

/// Menu-bar glyph states: calm template by default; badge only when needed; arc only while refreshing.
enum MenuBarIconKind: Equatable {
    case idle
    case warning
    case critical
    case error
    /// Refreshing uses a temporary rotating arc; angle is supplied separately.
    case refreshing
}

/// Builds the status-item image (template cup + optional badge / refresh arc).
@MainActor
enum MenuBarIcon {
    static let pointSize = NSSize(width: 18, height: 18)

    /// Highest-severity glance state from current usage (refresh handled by caller).
    static func resolve(usage: UsageStore) -> MenuBarIconKind {
        if usage.isRefreshing {
            return .refreshing
        }

        if let worst = usage.worstUsedFraction {
            if worst >= 0.95 {
                return .critical
            }
            if worst >= 0.80 {
                return .warning
            }
            return .idle
        }

        let snaps = usage.visibleSnapshots
        guard !snaps.isEmpty else { return .idle }

        let hasError = snaps.contains {
            if case .error = $0.status { return true }
            return false
        }
        let hasOk = snaps.contains {
            if case .ok = $0.status { return true }
            return false
        }
        // Error(s) and nothing OK with metrics → error badge.
        if hasError, !hasOk {
            return .error
        }
        return .idle
    }

    static func tooltipSuffix(for kind: MenuBarIconKind) -> String? {
        switch kind {
        case .idle, .refreshing:
            return nil
        case .warning:
            return "Warning"
        case .critical:
            return "Limit Reached"
        case .error:
            return "Unavailable"
        }
    }

    /// Compose the status item image for the given kind and optional refresh phase (0…1).
    /// Monochrome only: no colored badges. Exception detail lives in the menu / tooltip.
    static func image(kind: MenuBarIconKind, refreshPhase: CGFloat = 0) -> NSImage {
        switch kind {
        case .idle, .warning, .critical, .error:
            return templateCupImage() ?? symbolFallback()
        case .refreshing:
            return composed(refreshPhase: refreshPhase)
        }
    }

    // MARK: - Template cup asset

    static func templateCupImage() -> NSImage? {
        let point = pointSize
        let image = NSImage(size: point)
        image.isTemplate = true

        let scales: [(name: String, pixels: CGFloat)] = [
            ("MenuBarIcon", 18),
            ("MenuBarIcon@2x", 36),
            ("MenuBarIcon@3x", 54),
        ]

        var added = false
        for entry in scales {
            guard let url = AppResources.url(name: entry.name, ext: "png", subdirectory: "MenuBar"),
                  let data = try? Data(contentsOf: url),
                  let rep = NSBitmapImageRep(data: data)
            else { continue }
            rep.size = point
            image.addRepresentation(rep)
            added = true
        }

        if !added {
            guard let base = AppResources.image(name: "MenuBarIcon", subdirectory: "MenuBar")
                ?? AppResources.image(name: "MenuBarIcon-16", subdirectory: "MenuBar")
            else { return nil }
            base.size = point
            base.isTemplate = true
            return base
        }
        return image
    }

    // MARK: - Refresh composition (monochrome label color)

    private static func composed(refreshPhase: CGFloat) -> NSImage {
        let size = pointSize
        // Draw at 3× for sharpness, present at 18pt.
        let scale: CGFloat = 3
        let px = NSSize(width: size.width * scale, height: size.height * scale)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(px.width),
            pixelsHigh: Int(px.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return templateCupImage() ?? symbolFallback()
        }

        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = ctx
            ctx.imageInterpolation = .high
            ctx.shouldAntialias = true

            let rect = NSRect(origin: .zero, size: size)
            NSColor.clear.setFill()
            rect.fill()

            if let cup = templateCupImage() {
                let cupRect = rect.insetBy(dx: 0.5, dy: 0.5)
                let tinted = tintedTemplate(cup, color: .labelColor, size: cupRect.size)
                tinted.draw(in: cupRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            }

            drawRefreshArc(in: rect, phase: refreshPhase)
        }
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        image.isTemplate = false
        return image
    }

    private static func tintedTemplate(_ template: NSImage, color: NSColor, size: NSSize) -> NSImage {
        let out = NSImage(size: size)
        out.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        template.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1)
        color.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)
        out.unlockFocus()
        out.isTemplate = false
        return out
    }

    private static func drawRefreshArc(in rect: NSRect, phase: CGFloat) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.46
        let start = phase * 360.0
        let end = start + 270.0

        let path = NSBezierPath()
        path.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        path.lineWidth = 1.15
        path.lineCapStyle = .round
        NSColor.labelColor.withAlphaComponent(0.85).setStroke()
        path.stroke()
    }

    private static func symbolFallback() -> NSImage {
        let names = [AppSymbols.app, AppSymbols.appFallback, "cup.and.saucer", "circle.fill"]
        for name in names {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: "Cuprim") {
                let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
                let configured = image.withSymbolConfiguration(config) ?? image
                configured.isTemplate = true
                configured.size = pointSize
                return configured
            }
        }
        let image = NSImage(size: pointSize)
        image.lockFocus()
        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: 2, y: 2, width: 14, height: 14), xRadius: 3, yRadius: 3).fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
