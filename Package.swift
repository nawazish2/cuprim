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
        .executableTarget(
            name: "Cuprim",
            dependencies: [
                "CuprimCore",
                "CuprimProviders",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Cuprim",
            // Resources are copied into the .app by script/package_app.sh (Bundle.main).
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "CuprimTests",
            dependencies: ["CuprimCore", "CuprimProviders"],
            path: "Tests/CuprimTests"
        )
    ]
)
