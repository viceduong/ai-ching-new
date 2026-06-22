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
    dependencies: [
        // On non-Apple platforms, use swift-crypto instead of CryptoKit
        // .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "AiChingCore",
            dependencies: [
                // "Crypto"  // uncomment for non-Apple platforms
            ],
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
