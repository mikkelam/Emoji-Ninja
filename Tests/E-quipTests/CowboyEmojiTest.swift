import AppKit
import XCTest

@testable import equiplib

final class CowboyEmojiTest: XCTestCase {

    var dataManager: EmojiDataManager!

    override func setUpWithError() throws {
        dataManager = EmojiDataManager.shared
    }

    @MainActor
    func testCowboyEmojiFoundInCowSearch() throws {
        // This test verifies that searching for "cow" returns the cowboy hat emoji (🤠)
        // because "cow" is a substring of "cowboy" in the emoji's tags

        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        // Verify cowboy hat emoji is in results
        let cowboyEmoji = results.first { $0.unicode == "🤠" }
        XCTAssertNotNil(
            cowboyEmoji, "Cowboy hat emoji (🤠) should be found when searching for 'cow'")

        // Verify it has the expected properties
        if let cowboy = cowboyEmoji {
            XCTAssertEqual(cowboy.label, "cowboy hat face")
            XCTAssertEqual(cowboy.hexcode, "1F920")
            XCTAssertTrue(cowboy.tags?.contains("cowboy") ?? false, "Should have 'cowboy' tag")
        }

        // Verify cow emojis are also found
        let actualCowEmoji = results.first { $0.unicode == "🐄" }
        XCTAssertNotNil(actualCowEmoji, "Regular cow emoji (🐄) should also be found")

        let cowFaceEmoji = results.first { $0.unicode == "🐮" }
        XCTAssertNotNil(cowFaceEmoji, "Cow face emoji (🐮) should also be found")
    }

    @MainActor
    func testSearchKitCowboySearch() throws {
        // Test that the hybrid SearchKit approach also finds cowboy emoji
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        let cowboyEmoji = results.first { $0.unicode == "🤠" }
        XCTAssertNotNil(
            cowboyEmoji, "SearchKit should find cowboy hat emoji when searching for 'cow'")
    }

    @MainActor
    func testCowboyEmojiDirectSearch() throws {
        // Test direct search for "cowboy"
        let results = dataManager.searchEmojisWithSearchKit(query: "cowboy")

        let cowboyEmoji = results.first { $0.unicode == "🤠" }
        XCTAssertNotNil(cowboyEmoji, "Should find cowboy emoji when searching for 'cowboy'")
    }

    func testCowboyEmojiSupportChecker() throws {
        // Test the emoji support checker directly on cowboy emoji
        let cowboyUnicode = "🤠"

        // Test visual bounds check
        let systemFont = NSFont.systemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: systemFont]
        let attributedString = NSAttributedString(string: cowboyUnicode, attributes: attributes)
        let size = attributedString.size()

        print("Cowboy emoji support analysis:")
        print("  Unicode: \(cowboyUnicode)")
        print("  Rendered size: \(size.width) x \(size.height)")
        print("  Size check passes: \(size.width > 5 && size.height > 5)")

        // Check if it would pass the current support check
        let wouldPass = size.width > 5 && size.height > 5

        if !wouldPass {
            print("❌ Cowboy emoji fails the support check!")
            print("   This explains why it's not showing in the app UI")
        } else {
            print("✅ Cowboy emoji passes the support check")
        }

        // Find cowboy in dataset and check against library search
        let allEmojis = dataManager.getAllEmojis()
        let cowboyEmoji = allEmojis.first { $0.unicode == cowboyUnicode }

        XCTAssertNotNil(cowboyEmoji, "Cowboy emoji should exist in dataset")

        // The test should still pass even if the emoji fails visual bounds check
        // because that's the actual behavior we're investigating
        if let cowboy = cowboyEmoji {
            print("  Found in dataset: \(cowboy.label)")
        }
    }
}
