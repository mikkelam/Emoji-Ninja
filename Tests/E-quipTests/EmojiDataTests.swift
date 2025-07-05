import XCTest

@testable import equiplib

final class EmojiDataTests: XCTestCase {
    // MARK: - Data Loading Tests

    func testDataLoading() {
        print("\n📦 Testing Data Loading...")

        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Test basic loading
        assert(!allEmojis.isEmpty, "❌ No emojis loaded")
        print("✅ Loaded \(allEmojis.count) emojis")

        // Test that we have expected minimum count
        assert(allEmojis.count > 1000, "❌ Suspiciously few emojis loaded")
        print("✅ Emoji count looks reasonable")

        // Test that emojis have required properties
        let sampleEmoji = allEmojis.first!
        assert(!sampleEmoji.unicode.isEmpty, "❌ Emoji missing unicode")
        assert(!sampleEmoji.label.isEmpty, "❌ Emoji missing label")
        assert(!sampleEmoji.hexcode.isEmpty, "❌ Emoji missing hexcode")
        print("✅ Emoji properties are complete")
    }

    // MARK: - Filtering Tests

    func testFiltering() {
        print("\n🔍 Testing Emoji Filtering...")

        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Test that regional indicators are filtered out
        let hasRegionalIndicators = allEmojis.contains { emoji in
            emoji.label.contains("regional indicator")
        }
        assert(!hasRegionalIndicators, "❌ Regional indicators not filtered out")
        print("✅ Regional indicators filtered out")

        // Test that skin tone modifiers are filtered out
        let hasSkinToneModifiers = allEmojis.contains { emoji in
            emoji.label.lowercased().contains("skin tone")
        }
        assert(!hasSkinToneModifiers, "❌ Skin tone modifiers not filtered out")
        print("✅ Skin tone modifiers filtered out")

        // Test that all emojis are marked as useful
        let allUseful = allEmojis.allSatisfy { $0.isUseful }
        assert(allUseful, "❌ Some non-useful emojis passed through filter")
        print("✅ All loaded emojis marked as useful")

    }

    // MARK: - Categorization Tests

    func testCategorization() {
        print("\n📁 Testing Emoji Categorization...")

        let dataManager = EmojiDataManager.shared
        let availableGroups = dataManager.getAvailableGroups()

        // Test that we have reasonable number of groups
        assert(availableGroups.count >= 8, "❌ Too few emoji groups")
        print("✅ Found \(availableGroups.count) emoji groups")

        // Test that each group has emojis
        for group in availableGroups {
            let groupEmojis = dataManager.getEmojis(for: group)
            assert(!groupEmojis.isEmpty, "❌ Group \(group.name) has no emojis")
            print("  \(group.name): \(groupEmojis.count) emojis")
        }
        print("✅ All groups have emojis")

        // Test that categories work through EmojiCategory
        let availableCategories = EmojiCategory.availableCategories
        assert(!availableCategories.isEmpty, "❌ No categories available")
        print("✅ Categories accessible through EmojiCategory")

        // Test specific well-known categories
        let smileysCategory = availableCategories.first { $0.name.contains("Smileys") }
        assert(smileysCategory != nil, "❌ Smileys category not found")
        assert(!smileysCategory!.emojis.isEmpty, "❌ Smileys category has no emojis")
        print("✅ Smileys category has \(smileysCategory!.emojis.count) emojis")
    }

    // MARK: - Search Tests

    @MainActor
    func testSearch() {
        print("\n🔍 Testing Emoji Search...")

        let dataManager = EmojiDataManager.shared

        // Test basic search
        let smileResults = dataManager.searchEmojisWithSearchKit(query: "smile")
        XCTAssertFalse(smileResults.isEmpty, "No results for 'smile' search")
        print("✅ 'smile' search returned \(smileResults.count) results")

        // Test that search results contain the query
        let firstResult = smileResults.first!
        let containsSmile =
            firstResult.label.lowercased().contains("smile")
            || firstResult.tags?.contains { $0.lowercased().contains("smile") } == true
        XCTAssertTrue(containsSmile, "Search result doesn't contain search term")
        print("✅ Search results relevant to query")

        // Test empty search
        let emptyResults = dataManager.searchEmojisWithSearchKit(query: "")
        XCTAssertTrue(emptyResults.isEmpty, "Empty search should return no results")
        print("✅ Empty search returns no results")

        // Test nonsense search
        let nonsenseResults = dataManager.searchEmojisWithSearchKit(query: "xyzabc123")
        XCTAssertTrue(nonsenseResults.isEmpty, "Nonsense search should return no results")
        print("✅ Nonsense search returns no results")

        // Test case insensitive search
        let caseResults1 = dataManager.searchEmojisWithSearchKit(query: "SMILE")
        let caseResults2 = dataManager.searchEmojisWithSearchKit(query: "smile")
        XCTAssertEqual(caseResults1.count, caseResults2.count, "Search is case sensitive")
        print("✅ Search is case insensitive")

        // Test search through EmojiCategory
        let categorySearchResults = EmojiCategory.searchEmojis(query: "heart")
        XCTAssertFalse(categorySearchResults.isEmpty, "Category search failed")
        print("✅ Category search works: \(categorySearchResults.count) results for 'heart'")
    }

    // MARK: - Emoji Properties Tests

    func testEmojiProperties() {
        print("\n✅ Testing Emoji Properties...")

        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Test that all emojis have required properties
        for emoji in allEmojis.prefix(10) {  // Test first 10 for performance
            XCTAssertFalse(emoji.hexcode.isEmpty, "Emoji missing hexcode")
            XCTAssertFalse(emoji.label.isEmpty, "Emoji missing label")
            XCTAssertFalse(emoji.unicode.isEmpty, "Emoji missing unicode")
        }
        print("✅ All tested emojis have required properties")

        // Test emoji grouping
        let groupedEmojis = Dictionary(grouping: allEmojis) { $0.group ?? -1 }
        XCTAssertTrue(groupedEmojis.count > 1, "Emojis should have multiple groups")
        print("✅ Emojis are properly grouped into \(groupedEmojis.count) groups")

        // Test that useful filtering works
        let usefulEmojis = allEmojis.filter { $0.isUseful }
        XCTAssertEqual(usefulEmojis.count, allEmojis.count, "All loaded emojis should be useful")
        print("✅ Useful emoji filtering works correctly")
    }

    // MARK: - Performance Tests

    @MainActor
    func testPerformance() {
        print("\n⚡ Testing Performance...")

        let dataManager = EmojiDataManager.shared

        // Test search performance
        let start = Date()
        let _ = dataManager.searchEmojisWithSearchKit(query: "smile")
        let searchTime = Date().timeIntervalSince(start)

        XCTAssertLessThan(searchTime, 0.1, "Search took too long: \(searchTime)s")
        print("✅ Search performance: \(String(format: "%.3f", searchTime))s")

        // Test category loading performance
        let categoryStart = Date()
        let availableGroups = dataManager.getAvailableGroups()
        for group in availableGroups {
            _ = dataManager.getEmojis(for: group)
        }
        let categoryTime = Date().timeIntervalSince(categoryStart)

        XCTAssertLessThan(categoryTime, 0.01, "Category loading too slow: \(categoryTime)s")
        print("✅ Category loading performance: \(String(format: "%.3f", categoryTime))s")

        // Test memory usage (basic check)
        let allEmojis = dataManager.getAllEmojis()
        let memoryEstimate = allEmojis.count * 200  // rough estimate of bytes per emoji
        assert(memoryEstimate < 1_000_000, "❌ Memory usage too high: ~\(memoryEstimate) bytes")
        print("✅ Memory usage reasonable: ~\(memoryEstimate) bytes")
    }

    // MARK: - Data Integrity Tests

    static func validateDataIntegrity() {
        print("\n🔍 Validating Data Integrity...")

        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        // Check for duplicates
        let unicodeSet = Set(allEmojis.map { $0.unicode })
        assert(unicodeSet.count == allEmojis.count, "❌ Duplicate emojis found")
        print("✅ No duplicate emojis")

        // Check for empty unicode
        let hasEmptyUnicode = allEmojis.contains { $0.unicode.isEmpty }
        assert(!hasEmptyUnicode, "❌ Found emojis with empty unicode")
        print("✅ All emojis have unicode")

        // Check for reasonable hexcode format
        let hasInvalidHexcode = allEmojis.contains { emoji in
            emoji.hexcode.isEmpty || emoji.hexcode.contains(" ")
        }
        assert(!hasInvalidHexcode, "❌ Found emojis with invalid hexcode")
        print("✅ All emojis have valid hexcode")

        // Check group distribution
        let groupCounts = EmojiGroup.allCases.map { group in
            (group, dataManager.getEmojis(for: group).count)
        }
        let hasEmptyGroups = groupCounts.contains { $0.1 == 0 }
        if hasEmptyGroups {
            print("⚠️  Warning: Some emoji groups are empty")
        } else {
            print("✅ All emoji groups have content")
        }
    }
}

// MARK: - Helper Extensions
