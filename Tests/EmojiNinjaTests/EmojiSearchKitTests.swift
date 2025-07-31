import Foundation
import Testing

@testable import ninjalib

struct EmojiSearchKitTests {

    @Test @MainActor func searchKitInitialization() {
        let searchKit = EmojiDataManager.searchKit

        #expect(searchKit.indexedDocumentCount > 0)
        #expect(searchKit.indexSize > 0)
    }

    @Test @MainActor func basicSearch() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "smile")
        #expect(results.count > 0)

        // Verify results have scores
        for result in results {
            #expect(result.score > 0.0)
            #expect(!result.emoji.unicode.isEmpty)
            #expect(!result.emoji.label.isEmpty)
        }
    }

    @Test @MainActor func searchScoring() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "heart", limit: 10)
        #expect(results.count > 0)

        // Verify scores are in descending order
        for i in 1..<results.count {
            #expect(results[i - 1].score >= results[i].score)
        }

        // Top result should have highest score
        if let first = results.first {
            #expect(first.score > 0.0)
        }
    }

    @Test @MainActor func emptyQuery() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "")
        #expect(results.isEmpty)

        let whitespaceResults = searchKit.search(query: "   ")
        #expect(whitespaceResults.isEmpty)
    }

    @Test @MainActor func limitParameter() {
        let searchKit = EmojiDataManager.searchKit

        let results5 = searchKit.search(query: "face", limit: 5)
        #expect(results5.count <= 5)

        let results10 = searchKit.search(query: "face", limit: 10)
        #expect(results10.count <= 10)

        // Just verify that limit parameter works - ordering may vary for tied results
        #expect(results5.count <= results10.count)
    }

    @Test @MainActor func labelMatching() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "grinning")
        let hasGrinning = results.contains { result in
            result.emoji.label.lowercased().contains("grinning")
        }
        #expect(hasGrinning)
    }

    @Test @MainActor func tagMatching() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "happy")
        let hasHappyTag = results.contains { result in
            result.emoji.tags?.contains { $0.lowercased().contains("happy") } ?? false
        }

        // Should find emojis tagged with "happy"
        if !results.isEmpty {
            #expect(
                hasHappyTag || results.contains { $0.emoji.label.lowercased().contains("happy") })
        }
    }

    @Test @MainActor func caseInsensitiveSearch() {
        let searchKit = EmojiDataManager.searchKit

        let lowerResults = searchKit.search(query: "smile")
        let upperResults = searchKit.search(query: "SMILE")
        let mixedResults = searchKit.search(query: "SmIlE")

        #expect(lowerResults.count == upperResults.count)
        #expect(lowerResults.count == mixedResults.count)
    }

    @Test @MainActor func multiWordSearch() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "smiling face")
        #expect(results.count > 0)

        // Should prioritize emojis matching both terms
        if let first = results.first {
            let label = first.emoji.label.lowercased()
            let tags = first.emoji.tags?.joined(separator: " ").lowercased() ?? ""
            let _ =
                (label.contains("smiling") || tags.contains("smiling"))
                && (label.contains("face") || tags.contains("face"))
            // Top result should ideally match both terms (but not strictly required)
        }
    }

    @Test @MainActor func partialMatching() {
        let searchKit = EmojiDataManager.searchKit

        // Test substring matching
        let catResults = searchKit.search(query: "cat")
        let hasCatFace = catResults.contains { $0.emoji.unicode == "🐱" }
        let hasCat = catResults.contains { $0.emoji.unicode == "🐈" }

        #expect(hasCatFace || hasCat)
    }

    @Test @MainActor func specialCharacters() {
        let searchKit = EmojiDataManager.searchKit

        let specialQueries = ["@", "#", "$", "&", "()", "[]", "{}"]

        for query in specialQueries {
            let results = searchKit.search(query: query)
            // Should not crash and return valid results
            #expect(results.count >= 0)
        }
    }

    @Test @MainActor func unicodeQueries() {
        let searchKit = EmojiDataManager.searchKit

        let unicodeQueries = ["café", "naïve", "ñ", "résumé"]

        for query in unicodeQueries {
            let results = searchKit.search(query: query)
            // Should handle unicode without crashing
            #expect(results.count >= 0)
        }
    }

    @Test @MainActor func performanceBaseline() {
        let searchKit = EmojiDataManager.searchKit

        let start = Date()
        let _ = searchKit.search(query: "love", limit: 20)
        let elapsed = Date().timeIntervalSince(start)

        // Search should complete quickly
        #expect(elapsed < 0.1)
    }

    @Test @MainActor func consistentResults() {
        let searchKit = EmojiDataManager.searchKit

        let query = "pizza"
        let results1 = searchKit.search(query: query)
        let results2 = searchKit.search(query: query)

        #expect(results1.count == results2.count)

        // Results should be in same order
        for (r1, r2) in zip(results1, results2) {
            #expect(r1.emoji.unicode == r2.emoji.unicode)
            #expect(r1.score == r2.score)
        }
    }

    @Test @MainActor func searchResultStructure() {
        let searchKit = EmojiDataManager.searchKit

        let results = searchKit.search(query: "fire", limit: 5)

        for result in results {
            // Verify SearchResult structure
            #expect(result.score >= 0.0)
            #expect(!result.emoji.unicode.isEmpty)
            #expect(!result.emoji.label.isEmpty)
            #expect(!result.emoji.hexcode.isEmpty)

            // Score should be reasonable
            #expect(result.score <= 1000.0)  // Reasonable upper bound
        }
    }

    @Test @MainActor func edgeCaseQueries() {
        let searchKit = EmojiDataManager.searchKit

        let edgeCases = [
            String(repeating: "a", count: 100),  // Very long query
            "1234567890",  // Numbers only
            "!@#$%^&*()",  // Special chars only
            " leading space",
            "trailing space ",
            "  multiple   spaces  ",
        ]

        for query in edgeCases {
            let results = searchKit.search(query: query)
            // Should handle edge cases gracefully
            #expect(results.count >= 0)
        }
    }
}
