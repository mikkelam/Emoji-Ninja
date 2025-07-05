// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "E-quip",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
        .package(url: "https://github.com/danielsaidi/EmojiKit.git", from: "1.7.4"),
    ],
    targets: [
        .executableTarget(
            name: "E-quip",
            dependencies: [
                "HotKey",
                "EmojiKit",
            ]
        )
    ]
)
