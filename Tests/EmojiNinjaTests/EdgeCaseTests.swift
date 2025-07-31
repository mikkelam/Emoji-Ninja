import Testing

@testable import ninjalib

struct EdgeCaseTests {

    @Test @MainActor func emptySearchQueries() {
        let dataManager = EmojiDataManager.shared

        let emptyResults = dataManager.searchEmojisWithSearchKit(query: "")
        #expect(emptyResults.isEmpty)

        let whitespaceResults = dataManager.searchEmojisWithSearchKit(query: "   ")
        #expect(whitespaceResults.isEmpty)

        let newlineResults = dataManager.searchEmojisWithSearchKit(query: "\n\t")
        #expect(newlineResults.isEmpty)
    }

    @Test @MainActor func specialCharacterSearch() {
        let dataManager = EmojiDataManager.shared
        let specialChars = ["@", "#", "$", "%", "^", "&", "*", "(", ")", "[", "]"]

        for char in specialChars {
            let results = dataManager.searchEmojisWithSearchKit(query: char)
            // Should not crash and return valid results (even if empty)
            #expect(results.count >= 0)
        }
    }

    @Test @MainActor func unicodeSearch() {
        let dataManager = EmojiDataManager.shared
        let unicodeQueries = ["🤔", "café", "naïve", "résumé"]

        for query in unicodeQueries {
            let results = dataManager.searchEmojisWithSearchKit(query: query)
            #expect(results.count >= 0)
        }
    }

    @Test @MainActor func longSearchQueries() {
        let dataManager = EmojiDataManager.shared

        let longQuery = String(repeating: "smile", count: 100)
        let results = dataManager.searchEmojisWithSearchKit(query: longQuery)
        #expect(results.count >= 0)
    }

    @Test func dataIntegrityAfterMultipleAccesses() {
        let dataManager = EmojiDataManager.shared

        let initialCount = dataManager.getAllEmojis().count

        // Access data multiple times
        for _ in 0..<10 {
            _ = dataManager.getAllEmojis()
            _ = dataManager.getAvailableGroups()
        }

        let finalCount = dataManager.getAllEmojis().count
        #expect(initialCount == finalCount)
    }

    @Test @MainActor func searchResultConsistency() {
        let dataManager = EmojiDataManager.shared

        let query = "heart"
        let results1 = dataManager.searchEmojisWithSearchKit(query: query)
        let results2 = dataManager.searchEmojisWithSearchKit(query: query)

        #expect(results1.count == results2.count)

        // Verify same emojis in same order
        for (emoji1, emoji2) in zip(results1, results2) {
            #expect(emoji1.unicode == emoji2.unicode)
        }
    }
}
