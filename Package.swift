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
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "ninjalib",
      dependencies: [],
      path: "Sources/ninjalib",
      resources: [
        .process("emoji_data.json"),
        .process("search_stats.json")
      ]
    ),
    .executableTarget(
      name: "emoji",
      dependencies: [
        "ninjalib"
      ],
      path: "Sources/emojininja",
      resources: [

        .process("Assets.xcassets")
      ]
    ),
    .testTarget(
      name: "EmojiNinjaTests",
      dependencies: ["ninjalib"]
    )
  ]
)
