// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TunerClient",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "TunerClient", targets: ["TunerClient"])
    ],
    dependencies: [
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "TunerClient",
            dependencies: [.product(name: "Core", package: "Core")],
            path: "Sources/TunerClient"
        ),
        .testTarget(
            name: "TunerClientTests",
            dependencies: ["TunerClient", "Core"],
            path: "Tests/TunerClientTests"
        ),
    ]
)