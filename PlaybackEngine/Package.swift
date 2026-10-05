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
        .package(path: "../Core")
    ],
    targets: [
        .binaryTarget(
            name: "VLCKit",
            path: "../Frameworks/VLCKit.xcframework"
        ),
        .binaryTarget(
            name: "MockVLCKit",
            path: "../Frameworks/MockVLCKit.xcframework"
        ),
        .target(
            name: "PlaybackEngine",
            dependencies: [
                .product(name: "Core", package: "Core"),
                "VLCKit"
            ],
            path: "Sources/PlaybackEngine"
        ),
        .testTarget(
            name: "PlaybackEngineTests",
            dependencies: ["Core", "MockVLCKit"],
            path: "Tests/PlaybackEngineTests"
        ),
    ]
)