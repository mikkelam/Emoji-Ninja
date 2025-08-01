// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Emoji Ninja",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ninjalib",
            targets: ["ninjalib"]
        ),
        .executable(
            name: "Emoji Ninja",
            targets: ["emoji"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "ninjalib",
            dependencies: [
                "HotKey"
            ],
            path: "Sources/ninjalib",
            resources: [
                .process("emoji_data.json")
            ]
        ),
        .executableTarget(
            name: "emoji",
            dependencies: [
                "ninjalib",
                "HotKey",
            ],
            path: "Sources/emojininja",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EmojiNinjaTests",
            dependencies: ["ninjalib"]
        ),
    ]
)
