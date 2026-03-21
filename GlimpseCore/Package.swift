// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlimpseCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GlimpseCore", targets: ["GlimpseCore"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.17.0"
        ),
    ],
    targets: [
        .target(
            name: "GlimpseCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]
        ),
        .testTarget(
            name: "GlimpseCoreTests",
            dependencies: ["GlimpseCore"]
        ),
    ]
)
