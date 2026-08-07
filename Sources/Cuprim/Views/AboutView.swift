import AppKit
import SwiftUI

/// OpenUsage-style centered About panel: icon, name, version, credit, GitHub.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 36)

            appIcon
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.28), radius: 16, y: 6)

            Text("Cuprim")
                .font(.system(size: 28, weight: .semibold))
                .padding(.top, 20)

            Text(OpenSourceInfo.versionString)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("Created by")
                        .foregroundStyle(.secondary)
                    Link(OpenSourceInfo.authorName, destination: OpenSourceInfo.authorURL)
                }

                HStack(spacing: 4) {
                    Text("Open source on")
                        .foregroundStyle(.secondary)
                    Link("GitHub", destination: OpenSourceInfo.repositoryURL)
                }
            }
            .font(.system(size: 13))
            .padding(.top, 22)

            Spacer(minLength: 36)
        }
        .frame(width: 320, height: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var appIcon: some View {
        if let image = AppIconImage.aboutImage() {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.16, blue: 0.19),
                                Color(red: 0.05, green: 0.06, blue: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.45, blue: 0.92),
                                Color(red: 0.0, green: 0.35, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

enum AppIconImage {
    /// Prefer the packaged Dock/Finder icon for About + Dock consistency.
    @MainActor
    static func aboutImage() -> NSImage? {
        if let named = NSImage(named: "AppIcon") {
            return named
        }
        if let about = AppResources.image(name: "AppIcon-About", subdirectory: "AppIcon") {
            return about
        }
        if let master = AppResources.image(name: "AppIcon-1024", subdirectory: "AppIcon") {
            return master
        }
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSApplication.shared.applicationIconImage
    }
}
