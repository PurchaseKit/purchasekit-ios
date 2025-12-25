// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PurchaseKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "PurchaseKit", targets: ["PurchaseKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/hotwired/hotwire-native-ios", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "PurchaseKit",
            dependencies: [
                .product(name: "HotwireNative", package: "hotwire-native-ios")
            ]
        )
    ]
)
