// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GuideIngestion",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "GuideIngestion", targets: ["GuideIngestion"])
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "GuideIngestion",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/GuideIngestion"
        ),
        .testTarget(
            name: "GuideIngestionTests",
            dependencies: ["GuideIngestion", "Core"],
            path: "Tests/GuideIngestionTests"
        ),
    ]
)