// swift-tools-version: 6.2
import PackageDescription

// TokenBar: macOS 26+ only (Liquid Glass). Build for Apple Silicon (arm64).
let package = Package(
    name: "TokenBar",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(name: "TokenBarCore", targets: ["TokenBarCore"]),
        .executable(name: "TokenBar", targets: ["TokenBar"])
    ],
    targets: [
        .target(
            name: "TokenBarCore",
            path: "Sources/TokenBarCore"
        ),
        .executableTarget(
            name: "TokenBar",
            dependencies: ["TokenBarCore"],
            path: "Sources/TokenBar",
            // Resources are copied into the .app by script/build_and_run.sh (Bundle.main).
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "TokenBarTests",
            dependencies: ["TokenBarCore"],
            path: "Tests/TokenBarTests"
        )
    ]
)
