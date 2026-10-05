// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TowerApp",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "TowerApp", targets: ["TowerApp"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../TunerClient"),
        .package(path: "../PlaybackEngine"),
        .package(path: "../UI")
    ],
    targets: [
        .executableTarget(
            name: "TowerApp",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "TunerClient", package: "TunerClient"),
                .product(name: "PlaybackEngine", package: "PlaybackEngine"),
                .product(name: "UI", package: "UI")
            ],
            path: "Sources/TowerApp",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)