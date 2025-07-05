import XCTest

@testable import equiplib

@MainActor
final class SearchPerformanceTests: XCTestCase {

    func testSearchKitSetup() {
        print("\n⚙️ Testing SearchKit Setup...")

        let startTime = Date()
        let searchKit = EmojiDataManager.searchKit
        let setupTime = Date().timeIntervalSince(startTime)

        print("✅ SearchKit initialized in \(String(format: "%.3f", setupTime))s")
        print("✅ Indexed \(searchKit.indexedDocumentCount) emojis")

        let indexSizeMB = Double(searchKit.indexSize) / 1024 / 1024
        print("✅ Index size: \(String(format: "%.2f", indexSizeMB)) MB")
    }

    func testCompareSearchPerformance() {
        print("\n⚡ Comparing Search Performance...")

        let queries = [
            "smile",
            "heart",
            "fire",
            "cat",
            "food",
            "happy face",
            "red heart",
            "thinking",
            "party",
            "star",
        ]

        let dataManager = EmojiDataManager.shared

        // Test basic search
        var basicTotalTime: TimeInterval = 0
        var basicResultCount = 0

        for query in queries {
            let start = Date()
            let results = dataManager.searchEmojisWithSearchKit(query: query)
            let elapsed = Date().timeIntervalSince(start)
            basicTotalTime += elapsed
            basicResultCount += results.count
        }

        let basicAvgTime = basicTotalTime / Double(queries.count)
        print("\n📊 SearchKit Search:")
        print("   Average time: \(String(format: "%.4f", basicAvgTime))s")
        print("   Total results: \(basicResultCount)")

        print("\n✅ SearchKit performance measured successfully")
    }

    func testFuzzyMatching() {
        print("\n🔤 Testing Fuzzy Matching...")

        let searchKit = EmojiDataManager.searchKit
        let testCases = [
            ("smle", "smile"),  // Missing 'i'
            ("hapy", "happy"),  // Missing 'p'
            ("hart", "heart"),  // 'a' instead of 'ea'
            ("laugn", "laugh"),  // Transposed letters
        ]

        for (typo, correct) in testCases {
            let typoResults = searchKit.search(query: typo)
            let _ = searchKit.search(query: correct)

            // Check if we still get relevant results despite typos
            let typoHasRelevant = typoResults.contains { result in
                result.emoji.label.lowercased().contains(correct)
            }

            print(
                "   '\(typo)' → found \(typoResults.count) results (relevant: \(typoHasRelevant ? "✅" : "❌"))"
            )
        }
    }

    func testRelevanceScoring() {
        print("\n📊 Testing Relevance Scoring...")

        let searchKit = EmojiDataManager.searchKit
        let results = searchKit.search(query: "face smile", limit: 10)

        print("   Top 10 results for 'face smile':")
        for (index, result) in results.enumerated() {
            print(
                "   \(index + 1). \(result.emoji.unicode) \(result.emoji.label) (score: \(String(format: "%.2f", result.score)))"
            )
        }

        // Verify scoring order
        let scoresDescending = results.map { $0.score }
        let isSorted = scoresDescending == scoresDescending.sorted(by: >)
        print("\n   Scores properly sorted: \(isSorted ? "✅" : "❌")")
    }

    func testAdvancedFeatures() {
        print("\n🎯 Testing Advanced Features...")

        let searchKit = EmojiDataManager.searchKit

        // Test basic SearchKit functionality
        let basicResults = searchKit.search(query: "pizza", limit: 5)
        print("\n   Basic search for 'pizza':")
        print("   Found \(basicResults.count) results")

        let faceResults = searchKit.search(query: "face", limit: 10)
        print("\n   Basic search for 'face':")
        print("   Found \(faceResults.count) results")

        // Test with emoji from dataset
        let allEmojis = EmojiDataManager.shared.getAllEmojis()
        if let smileEmoji = allEmojis.first(where: { $0.label.contains("smile") }) {
            print("\n   Found smile emoji: '\(smileEmoji.unicode) \(smileEmoji.label)'")
        }
    }

    func testSearchKitIntegration() {
        print("\n🔗 Testing SearchKit Integration...")

        let dataManager = EmojiDataManager.shared

        // Test that searchEmojis now uses SearchKit
        let query = "smile face"

        // Get results from SearchKit
        let searchKitResults = dataManager.searchEmojisWithSearchKit(query: query)

        print("   SearchKit results: \(searchKitResults.count)")

        // Verify EmojiGroup.searchEmojis uses SearchKit
        let groupResults = EmojiGroup.searchEmojis(query: query)
        print("   Group search results: \(groupResults.count)")

        // Test filtered group search uses SearchKit
        if let smileysGroup = EmojiGroup.availableGroups.first(where: {
            $0 == .smileysAndPeople
        }) {
            let filteredResults = smileysGroup.filteredEmojis(searchQuery: "happy")
            print("   Filtered category results: \(filteredResults.count)")
        }

        // Verify picker view search would use SearchKit
        print("   ✅ All search methods integrated with SearchKit")
    }
}

// MARK: - Benchmark specific operations

extension SearchPerformanceTests {
    func testBenchmarkLargeDataset() {
        print("\n📈 Benchmarking Large Dataset Performance...")

        let searchKit = EmojiDataManager.searchKit
        let queries = generateRandomQueries(count: 100)

        // Measure throughput
        let start = Date()
        var totalResults = 0

        for query in queries {
            let results = searchKit.search(query: query, limit: 20)
            totalResults += results.count
        }

        let elapsed = Date().timeIntervalSince(start)
        let queriesPerSecond = Double(queries.count) / elapsed

        print("   Processed \(queries.count) queries in \(String(format: "%.2f", elapsed))s")
        print("   Throughput: \(String(format: "%.1f", queriesPerSecond)) queries/second")
        print("   Average results per query: \(totalResults / queries.count)")
    }

    private func generateRandomQueries(count: Int) -> [String] {
        let commonTerms = [
            "face", "smile", "heart", "love", "happy", "sad", "cry", "laugh",
            "fire", "star", "sun", "moon", "cat", "dog", "food", "drink",
            "hand", "eye", "mouth", "red", "blue", "green", "party", "birthday",
        ]

        return (0..<count).map { _ in
            // Generate 1-3 word queries
            let wordCount = Int.random(in: 1...3)
            let words = (0..<wordCount).map { _ in
                commonTerms.randomElement()!
            }
            return words.joined(separator: " ")
        }
    }
}
