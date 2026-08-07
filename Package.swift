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
        .executable(name: "Cuprim", targets: ["Cuprim"])
    ],
    targets: [
        .target(
            name: "CuprimCore",
            path: "Sources/CuprimCore"
        ),
        .executableTarget(
            name: "Cuprim",
            dependencies: ["CuprimCore"],
            path: "Sources/Cuprim",
            // Resources are copied into the .app by script/build_and_run.sh (Bundle.main).
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "CuprimTests",
            dependencies: ["CuprimCore"],
            path: "Tests/CuprimTests"
        )
    ]
)
