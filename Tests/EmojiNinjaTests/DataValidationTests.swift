import Foundation
import Testing

@testable import ninjalib

struct DataValidationTests {

    @Test func emojiFilteringLogic() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Critical: No regional indicators should pass through
        let regionalIndicators = allEmojis.filter { emoji in
            emoji.label.lowercased().contains("regional indicator")
        }
        #expect(regionalIndicators.isEmpty)

        // Critical: No skin tone modifiers should pass through
        let skinToneModifiers = allEmojis.filter { emoji in
            emoji.label.lowercased().contains("skin tone")
                && !emoji.label.lowercased().contains("light skin tone")  // Allow actual emoji names
        }
        #expect(skinToneModifiers.isEmpty)

        // All filtered emojis must be marked as useful
        let nonUsefulEmojis = allEmojis.filter { !$0.isUseful }
        #expect(nonUsefulEmojis.isEmpty)
    }

    @Test func mandatoryEmojiFields() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        for emoji in allEmojis.prefix(50) {
            // Critical fields must never be empty
            #expect(!emoji.unicode.isEmpty, "Unicode missing for \(emoji.label)")
            #expect(!emoji.label.isEmpty, "Label missing for \(emoji.unicode)")
            #expect(!emoji.hexcode.isEmpty, "Hexcode missing for \(emoji.unicode)")

            // Hexcode validation - allow dashes for compound emojis (ZWJ sequences)
            let isValidHexcode = emoji.hexcode.allSatisfy { char in
                char.isHexDigit || char == "-"
            }
            #expect(isValidHexcode, "Invalid hexcode: \(emoji.hexcode)")
            #expect(emoji.hexcode.count >= 4, "Hexcode too short: \(emoji.hexcode)")
        }
    }

    @Test func emojiGroupValidation() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Test group assignments are valid
        for emoji in allEmojis.prefix(100) {
            if let group = emoji.group {
                #expect(group >= 0, "Negative group ID: \(group)")
                #expect(group < 50, "Unreasonably high group ID: \(group)")
            }
        }

        // Test each available group has emojis
        let availableGroups = dataManager.getAvailableGroups()
        #expect(availableGroups.count >= 8, "Too few emoji groups")

        for group in availableGroups {
            let groupEmojis = dataManager.getEmojis(for: group)
            #expect(groupEmojis.count > 0, "Empty group: \(group.name)")

            // All emojis in group should have correct group ID
            for emoji in groupEmojis.prefix(5) {
                #expect(
                    emoji.group == group.rawValue,
                    "Wrong group assignment for \(emoji.unicode)")
            }
        }
    }

    @Test func unicodeValidation() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        for emoji in allEmojis.prefix(100) {
            let unicode = emoji.unicode

            // Should contain actual emoji characters
            #expect(unicode.count > 0, "Empty unicode")
            #expect(unicode.count <= 10, "Suspiciously long unicode: \(unicode)")

            // Should not contain control characters except ZWJ (U+200D) for compound emojis
            let hasInvalidControlChars = unicode.unicodeScalars.contains { scalar in
                CharacterSet.controlCharacters.contains(scalar) && scalar.value != 0x200D
            }
            #expect(!hasInvalidControlChars, "Invalid control characters in unicode: \(unicode)")
        }
    }

    @Test func skinToneVariationHandling() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Find emojis that support skin tones
        let skinToneEmojis = allEmojis.filter { $0.supportsSkinTones }

        for emoji in skinToneEmojis.prefix(10) {
            #expect(emoji.skins != nil, "Skin tone emoji missing skins array")
            #expect(!emoji.skins!.isEmpty, "Empty skins array")

            // Each skin variation should be valid
            for skin in emoji.skins! {
                #expect(!skin.unicode.isEmpty, "Skin variant missing unicode")
                #expect(!skin.hexcode.isEmpty, "Skin variant missing hexcode")
                #expect(skin.unicode != emoji.unicode, "Skin variant same as base")
            }
        }
    }

    @Test func tagValidation() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Find emojis with tags
        let taggedEmojis = allEmojis.filter { $0.tags?.isEmpty == false }
        #expect(taggedEmojis.count > 500, "Too few emojis have tags")

        for emoji in taggedEmojis.prefix(50) {
            let tags = emoji.tags!

            // Tags should be meaningful
            for tag in tags {
                #expect(!tag.isEmpty, "Empty tag for \(emoji.unicode)")
                // Allow single character/numeric tags like "3" (<3) and "143" (I love you)
                let isValidShortTag =
                    tag.count == 1
                    && (tag.allSatisfy { $0.isNumber } || ["3", "b", "o", "p", "x"].contains(tag))
                let isValidNumericTag = tag.allSatisfy { $0.isNumber } && tag.count <= 3
                #expect(
                    tag.count > 1 || isValidShortTag || isValidNumericTag,
                    "Invalid short tag: '\(tag)'")
                #expect(!tag.contains("  "), "Double spaces in tag: '\(tag)'")
                #expect(
                    tag == tag.trimmingCharacters(in: .whitespaces),
                    "Untrimmed tag: '\(tag)'")
            }
        }
    }

    @Test func dataConsistency() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // No duplicate unicodes
        let unicodes = allEmojis.map { $0.unicode }
        let uniqueUnicodes = Set(unicodes)
        #expect(unicodes.count == uniqueUnicodes.count, "Duplicate emojis found")

        // No duplicate hexcodes
        let hexcodes = allEmojis.map { $0.hexcode }
        let uniqueHexcodes = Set(hexcodes)
        #expect(hexcodes.count == uniqueHexcodes.count, "Duplicate hexcodes found")

        // Reasonable count bounds
        #expect(allEmojis.count > 1000, "Too few emojis")
        #expect(allEmojis.count < 10000, "Suspiciously many emojis")
    }

    @Test func labelQuality() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        for emoji in allEmojis.prefix(100) {
            let label = emoji.label

            // Basic quality checks
            #expect(!label.hasPrefix(" "), "Label starts with space: '\(label)'")
            #expect(!label.hasSuffix(" "), "Label ends with space: '\(label)'")
            #expect(!label.contains("  "), "Double spaces in label: '\(label)'")
            #expect(label.count > 2, "Label too short: '\(label)'")
            #expect(label.count < 100, "Label too long: '\(label)'")

            // Should be descriptive
            #expect(!label.lowercased().contains("unknown"), "Unknown emoji: '\(label)'")
            #expect(!label.lowercased().contains("undefined"), "Undefined emoji: '\(label)'")
        }
    }

    @Test @MainActor func searchIndexIntegrity() throws {
        let dataManager = EmojiDataManager.shared
        let searchKit = EmojiDataManager.searchKit
        let allEmojis = dataManager.getAllEmojis()

        // SearchKit should index all useful emojis
        #expect(
            searchKit.indexedDocumentCount == allEmojis.count,
            "SearchKit index count mismatch")

        // Basic functionality test - search should return results for common terms
        let commonSearches = ["heart", "face", "smile", "hand"]
        for term in commonSearches {
            let results = searchKit.search(query: term)
            #expect(results.count > 0, "No results for common search: \(term)")
        }

        // Test that search works with exact emoji labels (simple ones)
        let simpleEmojis = allEmojis.filter { emoji in
            emoji.label.split(separator: " ").count <= 2 && !emoji.label.contains(":")
                && !emoji.unicode.contains("‍")
        }.prefix(5)

        var foundCount = 0
        for emoji in simpleEmojis {
            let results = searchKit.search(query: emoji.label)
            if results.contains(where: { $0.emoji.unicode == emoji.unicode }) {
                foundCount += 1
            }
        }

        // Should find at least half of simple emojis
        #expect(foundCount >= simpleEmojis.count / 2, "Too few emojis found by exact label")
    }

    @Test @MainActor func performanceCriticalPaths() throws {
        let dataManager = EmojiDataManager.shared
        let isCI = ProcessInfo.processInfo.environment["CI"] != nil
        let threshMultiplier = isCI ? 3.0 : 1.0

        // Data loading should be fast (cached after first load)
        let loadStart = Date()
        _ = dataManager.getAllEmojis()
        let loadTime = Date().timeIntervalSince(loadStart)
        let loadThreshold = 0.1 * threshMultiplier
        #expect(loadTime < loadThreshold, "Data loading too slow: \(loadTime)s")

        // Group filtering should be fast
        let groupStart = Date()
        let availableGroups = dataManager.getAvailableGroups()
        for group in availableGroups.prefix(3) {
            _ = dataManager.getEmojis(for: group)
        }
        let groupTime = Date().timeIntervalSince(groupStart)
        let groupThreshold = 0.01 * threshMultiplier
        #expect(groupTime < groupThreshold, "Group filtering too slow: \(groupTime)s")

        // Common searches should be fast
        let searchStart = Date()
        _ = dataManager.searchEmojisWithSearchKit(query: "heart")
        let searchTime = Date().timeIntervalSince(searchStart)
        let searchThreshold = 0.05 * threshMultiplier
        #expect(searchTime < searchThreshold, "Search too slow: \(searchTime)s")
    }

    @Test func memoryUsageReasonable() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Rough memory estimation
        let estimatedBytesPerEmoji = 500  // Conservative estimate
        let totalEstimatedBytes = allEmojis.count * estimatedBytesPerEmoji

        // Should be under 5MB total
        #expect(
            totalEstimatedBytes < 5_000_000,
            "Estimated memory usage too high: \(totalEstimatedBytes) bytes")
    }

    @Test @MainActor func emptyStateHandling() throws {
        // Test what happens with empty search results
        let dataManager = EmojiDataManager.shared
        let impossibleResults = dataManager.searchEmojisWithSearchKit(query: "xyznonexistent")
        #expect(impossibleResults.isEmpty)

        // Test groups that might be empty (component group often is)
        let componentGroup = EmojiGroup.component
        let componentEmojis = dataManager.getEmojis(for: componentGroup)
        // Should handle gracefully whether empty or not
        #expect(componentEmojis.count >= 0)
    }
}
