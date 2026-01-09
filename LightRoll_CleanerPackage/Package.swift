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
    dependencies: [
        // Google Mobile Ads SDK
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "11.0.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LightRoll_CleanerFeature",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
                // Swift 6モード: 将来の完全移行のため一旦無効化
                // TODO: 全モジュールのSendable準拠を完了させてから.v6に移行
                // 既に@Sendableは追加済み（getFileSizesメソッド）
            ]
        ),
        .testTarget(
            name: "LightRoll_CleanerFeatureTests",
            dependencies: [
                "LightRoll_CleanerFeature",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
                // テストではSwift 6モードを有効化してSwift Testingを使用
            ]
        ),
        .testTarget(
            name: "DocumentValidationTests",
            dependencies: []
        ),
    ]
)
