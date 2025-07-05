import XCTest

@testable import ninjalib

final class EmojiSearchTests: XCTestCase {

    var dataManager: EmojiDataManager!

    override func setUpWithError() throws {
        dataManager = EmojiDataManager.shared
    }

    @MainActor
    func testCowboySearch() throws {
        // Test searching for "cow" should return both cow emoji and cowboy hat emoji
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        // Print results for debugging
        print("Search results for 'cow':")
        for emoji in results {
            print("  \(emoji.unicode) - \(emoji.label) - tags: \(emoji.tags ?? [])")
        }

        // Check that we have results
        XCTAssertFalse(results.isEmpty, "Search for 'cow' should return results")

        // Look for cowboy hat face emoji (🤠)
        let cowboyHatEmoji = results.first { $0.unicode == "🤠" }
        XCTAssertNotNil(cowboyHatEmoji, "Search for 'cow' should include cowboy hat face emoji (🤠)")

        // Look for cow emoji (🐄)
        let cowEmoji = results.first { $0.unicode == "🐄" }
        XCTAssertNotNil(cowEmoji, "Search for 'cow' should include cow emoji (🐄)")

        // Verify cowboy hat emoji has correct properties
        if let cowboy = cowboyHatEmoji {
            XCTAssertEqual(cowboy.label, "cowboy hat face")
            XCTAssertEqual(cowboy.hexcode, "1F920")
            XCTAssertTrue(
                cowboy.tags?.contains("cowboy") ?? false, "Cowboy emoji should have 'cowboy' tag")
        }
    }

    @MainActor
    func testCowboyExactSearch() throws {
        // Test searching for "cowboy" specifically
        let results = dataManager.searchEmojisWithSearchKit(query: "cowboy")

        print("Search results for 'cowboy':")
        for emoji in results {
            print("  \(emoji.unicode) - \(emoji.label) - tags: \(emoji.tags ?? [])")
        }

        // Should definitely find cowboy hat emoji
        let cowboyHatEmoji = results.first { $0.unicode == "🤠" }
        XCTAssertNotNil(
            cowboyHatEmoji, "Search for 'cowboy' should include cowboy hat face emoji (🤠)")
    }

    @MainActor
    func testSearchKitCowboySearch() throws {
        // Test SearchKit implementation
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        print("SearchKit results for 'cow':")
        for emoji in results {
            print("  \(emoji.unicode) - \(emoji.label) - tags: \(emoji.tags ?? [])")
        }

        // Check that we have results
        XCTAssertFalse(results.isEmpty, "SearchKit search for 'cow' should return results")

        // Look for cowboy hat face emoji (🤠)
        let cowboyHatEmoji = results.first { $0.unicode == "🤠" }
        XCTAssertNotNil(
            cowboyHatEmoji, "SearchKit search for 'cow' should include cowboy hat face emoji (🤠)")

        // Look for cow emoji (🐄)
        let cowEmoji = results.first { $0.unicode == "🐄" }
        XCTAssertNotNil(cowEmoji, "SearchKit search for 'cow' should include cow emoji (🐄)")
    }

    func testTagBasedSearch() throws {
        // Test that tag-based searching works
        let allEmojis = dataManager.getAllEmojis()

        // Find the cowboy emoji directly
        let cowboyEmoji = allEmojis.first { $0.unicode == "🤠" }
        XCTAssertNotNil(cowboyEmoji, "Cowboy emoji should exist in the dataset")

        if let cowboy = cowboyEmoji {
            print("Cowboy emoji found: \(cowboy.unicode) - \(cowboy.label)")
            print("Tags: \(cowboy.tags ?? [])")

            // Verify it has the expected tags
            XCTAssertTrue(cowboy.tags?.contains("cowboy") ?? false, "Should have 'cowboy' tag")
            XCTAssertTrue(cowboy.tags?.contains("face") ?? false, "Should have 'face' tag")
            XCTAssertTrue(cowboy.tags?.contains("hat") ?? false, "Should have 'hat' tag")
        }
    }

    @MainActor
    func testPartialTagMatching() throws {
        // Test that partial tag matching works for "cow" substring
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        // Find all emojis that should match "cow"
        let cowMatches = results.filter { emoji in
            // Should match if label contains "cow" or any tag contains "cow"
            let labelMatch = emoji.label.lowercased().contains("cow")
            let tagMatch = emoji.tags?.contains { $0.lowercased().contains("cow") } ?? false
            return labelMatch || tagMatch
        }

        print("Emojis matching 'cow':")
        for emoji in cowMatches {
            print("  \(emoji.unicode) - \(emoji.label) - tags: \(emoji.tags ?? [])")
        }

        // Should include cowboy hat face
        let hasCowboy = cowMatches.contains { $0.unicode == "🤠" }
        XCTAssertTrue(hasCowboy, "Should find cowboy hat face emoji when searching for 'cow'")
    }

    @MainActor
    func testCowboyEmojiIndexing() throws {
        // Test that cowboy emoji is properly indexed and findable
        let allEmojis = dataManager.getAllEmojis()

        // Find cowboy emoji
        let cowboyEmoji = allEmojis.first { $0.unicode == "🤠" }
        XCTAssertNotNil(cowboyEmoji, "Cowboy emoji should exist in dataset")

        // Test if it can be found by searching for "cowboy"
        let cowboyResults = dataManager.searchEmojisWithSearchKit(query: "cowboy")
        let foundByCowboy = cowboyResults.contains { $0.unicode == "🤠" }
        XCTAssertTrue(foundByCowboy, "Should find cowboy emoji when searching for 'cowboy'")

        // Test if it can be found by searching for "hat"
        let hatResults = dataManager.searchEmojisWithSearchKit(query: "hat")
        let foundByHat = hatResults.contains { $0.unicode == "🤠" }
        XCTAssertTrue(foundByHat, "Should find cowboy emoji when searching for 'hat'")

        // Test if it can be found by searching for "face"
        let faceResults = dataManager.searchEmojisWithSearchKit(query: "face")
        let foundByFace = faceResults.contains { $0.unicode == "🤠" }
        XCTAssertTrue(foundByFace, "Should find cowboy emoji when searching for 'face'")
    }
}
