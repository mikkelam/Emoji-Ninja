import Testing

@testable import ninjalib

struct EmojiSearchTests {

    var dataManager: EmojiDataManager {
        EmojiDataManager.shared
    }

    @Test @MainActor func cowboySearch() throws {
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        #expect(!results.isEmpty)
        let cowboyHatEmoji = results.first { $0.unicode == "🤠" }
        #expect(cowboyHatEmoji != nil)

        let cowEmoji = results.first { $0.unicode == "🐄" }
        #expect(cowEmoji != nil)

        if let cowboy = cowboyHatEmoji {
            #expect(cowboy.label == "cowboy hat face")
            #expect(cowboy.hexcode == "1F920")
            #expect(cowboy.tags?.contains("cowboy") ?? false)
        }
    }

    @Test @MainActor func cowboyExactSearch() throws {
        let results = dataManager.searchEmojisWithSearchKit(query: "cowboy")
        let cowboyHatEmoji = results.first { $0.unicode == "🤠" }
        #expect(cowboyHatEmoji != nil)
    }

    @Test @MainActor func searchKitCowboySearch() throws {
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")

        #expect(!results.isEmpty)
        let cowboyHatEmoji = results.first { $0.unicode == "🤠" }
        #expect(cowboyHatEmoji != nil)

        let cowEmoji = results.first { $0.unicode == "🐄" }
        #expect(cowEmoji != nil)
    }

    @Test func tagBasedSearch() throws {
        let allEmojis = dataManager.getAllEmojis()
        let cowboyEmoji = allEmojis.first { $0.unicode == "🤠" }
        #expect(cowboyEmoji != nil)

        if let cowboy = cowboyEmoji {
            #expect(cowboy.tags?.contains("cowboy") ?? false)
            #expect(cowboy.tags?.contains("face") ?? false)
            #expect(cowboy.tags?.contains("hat") ?? false)
        }
    }

    @Test @MainActor func partialTagMatching() throws {
        let results = dataManager.searchEmojisWithSearchKit(query: "cow")
        let cowMatches = results.filter { emoji in
            let labelMatch = emoji.label.lowercased().contains("cow")
            let tagMatch = emoji.tags?.contains { $0.lowercased().contains("cow") } ?? false
            return labelMatch || tagMatch
        }

        let hasCowboy = cowMatches.contains { $0.unicode == "🤠" }
        #expect(hasCowboy)
    }

    @Test @MainActor func cowboyEmojiIndexing() throws {
        let allEmojis = dataManager.getAllEmojis()
        let cowboyEmoji = allEmojis.first { $0.unicode == "🤠" }
        #expect(cowboyEmoji != nil)

        let cowboyResults = dataManager.searchEmojisWithSearchKit(query: "cowboy")
        let foundByCowboy = cowboyResults.contains { $0.unicode == "🤠" }
        #expect(foundByCowboy)

        let hatResults = dataManager.searchEmojisWithSearchKit(query: "hat")
        let foundByHat = hatResults.contains { $0.unicode == "🤠" }
        #expect(foundByHat)

        let faceResults = dataManager.searchEmojisWithSearchKit(query: "face")
        let foundByFace = faceResults.contains { $0.unicode == "🤠" }
        #expect(foundByFace)
    }
}
