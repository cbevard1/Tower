// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tower",
    platforms: [
        .macOS(.v15)
    ],
    products: [],
    dependencies: [
        .package(path: "Core"),
        .package(path: "TunerClient"),
        .package(path: "PlaybackEngine"),
        .package(path: "UI"),
        .package(path: "TowerApp")
    ],
    targets: []
)