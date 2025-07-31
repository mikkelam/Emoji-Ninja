import Foundation
import Testing

@testable import ninjalib

struct ResourceLoadingTests {

    @Test func resourceBundleExists() {
        let bundle = Bundle.module
        #expect(bundle != Bundle.main)  // Should be using module bundle

        let url = bundle.url(forResource: "emoji_data", withExtension: "json")
        #expect(url != nil)
    }

    @Test func emojiDataFileExists() throws {
        let bundle = Bundle.module
        let url = try #require(bundle.url(forResource: "emoji_data", withExtension: "json"))

        #expect(FileManager.default.fileExists(atPath: url.path))

        let data = try Data(contentsOf: url)
        #expect(data.count > 0)
    }

    @Test func emojiDataIsValidJSON() throws {
        let bundle = Bundle.module
        let url = try #require(bundle.url(forResource: "emoji_data", withExtension: "json"))
        let data = try Data(contentsOf: url)

        // Should parse as JSON array
        let json = try JSONSerialization.jsonObject(with: data)
        #expect(json is [Any])

        let array = json as! [Any]
        #expect(array.count > 0)
    }

    @Test func emojiDataStructure() throws {
        let bundle = Bundle.module
        let url = try #require(bundle.url(forResource: "emoji_data", withExtension: "json"))
        let data = try Data(contentsOf: url)

        // Should decode to EmojibaseEmoji array
        let emojis = try JSONDecoder().decode([EmojibaseEmoji].self, from: data)
        #expect(emojis.count > 1000)  // Reasonable minimum

        // Verify first emoji has required fields
        let firstEmoji = try #require(emojis.first)
        #expect(!firstEmoji.unicode.isEmpty)
        #expect(!firstEmoji.label.isEmpty)
        #expect(!firstEmoji.hexcode.isEmpty)
    }

    @Test func dataIntegrityChecks() throws {
        let bundle = Bundle.module
        let url = try #require(bundle.url(forResource: "emoji_data", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let emojis = try JSONDecoder().decode([EmojibaseEmoji].self, from: data)

        // Check for duplicates
        let unicodes = emojis.map { $0.unicode }
        let uniqueUnicodes = Set(unicodes)
        #expect(unicodes.count == uniqueUnicodes.count)

        // All should have valid hexcodes
        for emoji in emojis.prefix(100) {
            #expect(!emoji.hexcode.isEmpty)
            // Allow dashes for compound emojis (ZWJ sequences)
            let isValidHexcode = emoji.hexcode.allSatisfy { char in
                char.isHexDigit || char == "-"
            }
            #expect(isValidHexcode)
        }
    }

    @Test func singletonDataManagerInitialization() {
        let manager1 = EmojiDataManager.shared
        let manager2 = EmojiDataManager.shared

        // Should be same instance
        #expect(manager1 === manager2)

        // Should have loaded data
        #expect(manager1.getAllEmojis().count > 0)
    }

    @Test func dataManagerLoadingPerformance() {
        let start = Date()
        _ = EmojiDataManager.shared.getAllEmojis()
        let elapsed = Date().timeIntervalSince(start)

        // Should load quickly (subsequent calls are cached)
        #expect(elapsed < 0.1)
    }

    @Test func resourcePathsExist() throws {
        let bundle = Bundle.module

        // Bundle should have resources
        let resourcePath = try #require(bundle.resourcePath)
        #expect(FileManager.default.fileExists(atPath: resourcePath))

        // emoji_data.json should exist
        let emojiDataPath = bundle.path(forResource: "emoji_data", ofType: "json")
        #expect(emojiDataPath != nil)
        #expect(FileManager.default.fileExists(atPath: emojiDataPath!))
    }

    @Test func handleCorruptedData() throws {
        // Test with invalid JSON data
        let invalidJSON = "{ invalid json }"
        let invalidData = invalidJSON.data(using: .utf8)!

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode([EmojibaseEmoji].self, from: invalidData)
        }
    }

    @Test func handleEmptyData() throws {
        let emptyData = Data()

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode([EmojibaseEmoji].self, from: emptyData)
        }
    }

    @Test func resourceAccessibility() {
        let bundle = Bundle.module

        // Bundle should be accessible - bundleIdentifier can be nil for module bundles
        #expect(bundle.resourceURL != nil)

        // Should be able to list resources
        let resourceKeys: [URLResourceKey] = [.nameKey, .isDirectoryKey]
        let resourceURL = bundle.resourceURL

        if let url = resourceURL {
            let resources = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: resourceKeys
            )
            #expect(resources != nil)
            #expect(resources!.count > 0)
        }
    }
}
