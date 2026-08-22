// swift-tools-version: 6.2
import PackageDescription

// Cuprim: macOS 26+ only (Liquid Glass). Build for Apple Silicon (arm64).
let package = Package(
    name: "Cuprim",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "CuprimCore", targets: ["CuprimCore"]),
        .library(name: "CuprimProviders", targets: ["CuprimProviders"]),
        .executable(name: "Cuprim", targets: ["Cuprim"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.7.1")
    ],
    targets: [
        .target(
            name: "CuprimCore",
            path: "Sources/CuprimCore"
        ),
        .target(
            name: "CuprimProviders",
            dependencies: ["CuprimCore"],
            path: "Sources/CuprimProviders"
        ),
        // All app code (stores, services, views, controllers) lives here rather
        // than in the executable, so `CuprimTests` can reach it with
        // `@testable import CuprimKit`. An executable target cannot be tested.
        .target(
            name: "CuprimKit",
            dependencies: [
                "CuprimCore",
                "CuprimProviders",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/CuprimKit"
        ),
        .executableTarget(
            name: "Cuprim",
            dependencies: ["CuprimKit"],
            path: "Sources/Cuprim",
            // Resources are copied into the .app by script/package_app.sh (Bundle.main).
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "CuprimTests",
            dependencies: ["CuprimCore", "CuprimProviders", "CuprimKit"],
            path: "Tests/CuprimTests"
        )
    ]
)
