// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "E-quip",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "equiplib",
            targets: ["equiplib"]
        ),
        .executable(
            name: "E-quip",
            targets: ["equipapp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "equiplib",
            dependencies: [
                "HotKey"
            ],
            path: "Sources/equiplib",
            resources: [
                .process("../Resources")
            ]
        ),
        .executableTarget(
            name: "equipapp",
            dependencies: [
                "equiplib",
                "HotKey",
            ],
            path: "Sources/equipapp"
        ),
        .testTarget(
            name: "E-quipTests",
            dependencies: ["equiplib"]
        ),
    ]
)
