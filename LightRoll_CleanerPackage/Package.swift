// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LightRoll_CleanerFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LightRoll_CleanerFeature",
            targets: ["LightRoll_CleanerFeature"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LightRoll_CleanerFeature",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "LightRoll_CleanerFeatureTests",
            dependencies: [
                "LightRoll_CleanerFeature"
            ]
        ),
    ]
)
