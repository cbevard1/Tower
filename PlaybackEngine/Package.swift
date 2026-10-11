// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PlaybackEngine",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PlaybackEngine", targets: ["PlaybackEngine"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../MockVLCKit")
    ],
    targets: [
        .target(
            name: "PlaybackEngine",
            dependencies: [
                .product(name: "Core", package: "Core"),
                "MockVLCKit"
            ],
            path: "Sources/PlaybackEngine"
        ),
        .testTarget(
            name: "PlaybackEngineTests",
            dependencies: ["PlaybackEngine", "Core", "MockVLCKit"],
            path: "Tests/PlaybackEngineTests"
        ),
    ]
)