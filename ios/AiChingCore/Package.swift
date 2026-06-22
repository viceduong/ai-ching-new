// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AiChingCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "AiChingCore",
            targets: ["AiChingCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AiChingCore",
            dependencies: [],
            exclude: [],
            resources: [
                .process("Resources/hexagrams.json"),
            ]
        ),
        .testTarget(
            name: "AiChingCoreTests",
            dependencies: ["AiChingCore"]
        ),
    ]
)
