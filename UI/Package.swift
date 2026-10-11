// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UI",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "UI", targets: ["UI"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../TunerClient"),
        .package(path: "../PlaybackEngine"),
        .package(path: "../MockVLCKit")
    ],
    targets: [
        .target(
            name: "UI",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "TunerClient", package: "TunerClient"),
                .product(name: "PlaybackEngine", package: "PlaybackEngine")
            ],
            path: "Sources/UI"
        ),
        .testTarget(
            name: "UITests",
            dependencies: ["UI", "Core", "TunerClient", "MockVLCKit"],
            path: "Tests/UITests",
            exclude: [
                "SettingsViewModelTests.swift.disabled",
                "TestUtilitiesSettings.swift.disabled"
            ]
        ),
    ]
)