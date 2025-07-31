import Foundation
import Testing

@testable import ninjalib

struct EmojiDataTests {

    @Test func dataLoading() throws {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        #expect(!allEmojis.isEmpty)
        #expect(allEmojis.count > 1000)

        let sampleEmoji = try #require(allEmojis.first)
        #expect(!sampleEmoji.unicode.isEmpty)
        #expect(!sampleEmoji.label.isEmpty)
        #expect(!sampleEmoji.hexcode.isEmpty)
    }

    @Test func filtering() {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        let hasRegionalIndicators = allEmojis.contains { emoji in
            emoji.label.contains("regional indicator")
        }
        #expect(!hasRegionalIndicators)

        let hasSkinToneModifiers = allEmojis.contains { emoji in
            emoji.label.lowercased().contains("skin tone")
        }
        #expect(!hasSkinToneModifiers)

        let allUseful = allEmojis.allSatisfy { $0.isUseful }
        #expect(allUseful)
    }

    @Test func categorization() throws {
        let dataManager = EmojiDataManager.shared
        let availableGroups = dataManager.getAvailableGroups()

        #expect(availableGroups.count >= 8)

        for group in availableGroups {
            let groupEmojis = dataManager.getEmojis(for: group)
            #expect(!groupEmojis.isEmpty, "Group \(group.name) has no emojis")
        }

        let groupsFromManager = dataManager.getAvailableGroups()
        #expect(!groupsFromManager.isEmpty)

        let smileysGroup = groupsFromManager.first { $0.name.contains("Smileys") }
        let group = try #require(smileysGroup)
        let smileysEmojis = dataManager.getEmojis(for: group)
        #expect(!smileysEmojis.isEmpty)
    }

    @Test @MainActor func search() throws {
        let dataManager = EmojiDataManager.shared

        let smileResults = dataManager.searchEmojisWithSearchKit(query: "smile")
        #expect(!smileResults.isEmpty)

        let firstResult = try #require(smileResults.first)
        let containsSmile =
            firstResult.label.lowercased().contains("smile")
            || firstResult.tags?.contains { $0.lowercased().contains("smile") } == true
        #expect(containsSmile)

        let emptyResults = dataManager.searchEmojisWithSearchKit(query: "")
        #expect(emptyResults.isEmpty)

        let nonsenseResults = dataManager.searchEmojisWithSearchKit(query: "xyzabc123")
        #expect(nonsenseResults.isEmpty)

        let caseResults1 = dataManager.searchEmojisWithSearchKit(query: "SMILE")
        let caseResults2 = dataManager.searchEmojisWithSearchKit(query: "smile")
        #expect(caseResults1.count == caseResults2.count)

        let searchResults = dataManager.searchEmojisWithSearchKit(query: "heart")
        #expect(!searchResults.isEmpty)
    }

    @Test func emojiProperties() {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        for emoji in allEmojis.prefix(10) {
            #expect(!emoji.hexcode.isEmpty)
            #expect(!emoji.label.isEmpty)
            #expect(!emoji.unicode.isEmpty)
        }

        let groupedEmojis = Dictionary(grouping: allEmojis) { $0.group ?? -1 }
        #expect(groupedEmojis.count > 1)

        let usefulEmojis = allEmojis.filter { $0.isUseful }
        #expect(usefulEmojis.count == allEmojis.count)
    }

    @Test @MainActor func performance() {
        let dataManager = EmojiDataManager.shared

        let start = Date()
        let _ = dataManager.searchEmojisWithSearchKit(query: "smile")
        let searchTime = Date().timeIntervalSince(start)
        #expect(searchTime < 0.1)

        let categoryStart = Date()
        let availableGroups = dataManager.getAvailableGroups()
        for group in availableGroups {
            _ = dataManager.getEmojis(for: group)
        }
        let categoryTime = Date().timeIntervalSince(categoryStart)
        #expect(categoryTime < 0.01)

        let allEmojis = dataManager.getAllEmojis()
        let memoryEstimate = allEmojis.count * 200
        #expect(memoryEstimate < 1_000_000)
    }

    @Test func dataIntegrity() {
        let dataManager = EmojiDataManager.shared
        let allEmojis = dataManager.getAllEmojis()

        let unicodeSet = Set(allEmojis.map { $0.unicode })
        #expect(unicodeSet.count == allEmojis.count)

        let hasEmptyUnicode = allEmojis.contains { $0.unicode.isEmpty }
        #expect(!hasEmptyUnicode)

        let hasInvalidHexcode = allEmojis.contains { emoji in
            emoji.hexcode.isEmpty || emoji.hexcode.contains(" ")
        }
        #expect(!hasInvalidHexcode)

        let groupsForCounts = dataManager.getAvailableGroups()
        let groupCounts = groupsForCounts.map { group in
            (group, dataManager.getEmojis(for: group).count)
        }
        let hasEmptyGroups = groupCounts.contains { $0.1 == 0 }
        #expect(!hasEmptyGroups)
    }
}
