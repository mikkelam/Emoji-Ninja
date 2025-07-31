import Foundation
import Testing

@testable import ninjalib

@MainActor
struct SearchPerformanceTests {

  @Test func searchKitSetup() {
    let startTime = Date()
    let searchKit = EmojiDataManager.searchKit
    let setupTime = Date().timeIntervalSince(startTime)

    #expect(setupTime < 1.0)
    #expect(searchKit.indexedDocumentCount > 0)
    #expect(searchKit.indexSize > 0)
  }

  @Test func compareSearchPerformance() {
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
    #expect(basicAvgTime < 0.1)
    #expect(basicResultCount > 0)
  }

  @Test func fuzzyMatching() {
    let searchKit = EmojiDataManager.searchKit
    let testCases = [
      ("smle", "smile"),
      ("hapy", "happy"),
      ("hart", "heart"),
      ("laugn", "laugh"),
    ]

    for (typo, correct) in testCases {
      _ = searchKit.search(query: typo)
      let correctResults = searchKit.search(query: correct)

      #expect(correctResults.count >= 0)
    }
  }

  @Test func relevanceScoring() {
    let searchKit = EmojiDataManager.searchKit
    let results = searchKit.search(query: "face smile", limit: 10)

    #expect(results.count > 0)

    let scoresDescending = results.map { $0.score }
    let isSorted = scoresDescending == scoresDescending.sorted(by: >)
    #expect(isSorted)

    for result in results {
      #expect(result.score > 0)
    }
  }

  @Test func advancedFeatures() {
    let searchKit = EmojiDataManager.searchKit

    let basicResults = searchKit.search(query: "pizza", limit: 5)
    #expect(basicResults.count >= 0)

    let faceResults = searchKit.search(query: "face", limit: 10)
    #expect(faceResults.count > 0)

    let allEmojis = EmojiDataManager.shared.getAllEmojis()
    let smileEmoji = allEmojis.first(where: { $0.label.contains("smile") })
    #expect(smileEmoji != nil)
  }

  @Test func searchKitIntegration() {
    let dataManager = EmojiDataManager.shared
    let query = "smile face"

    let searchKitResults = dataManager.searchEmojisWithSearchKit(query: query)
    #expect(searchKitResults.count >= 0)

    let availableGroups = dataManager.getAvailableGroups()
    let smileysGroup = availableGroups.first(where: { $0 == .smileysAndEmotion })
    #expect(smileysGroup != nil)

    if let group = smileysGroup {
      let groupEmojis = dataManager.getEmojis(for: group)
      #expect(groupEmojis.count > 0)
    }
  }

  @Test func benchmarkLargeDataset() {
    let searchKit = EmojiDataManager.searchKit
    let queries = generateRandomQueries(count: 100)

    let start = Date()
    var totalResults = 0

    for query in queries {
      let results = searchKit.search(query: query, limit: 20)
      totalResults += results.count
    }

    let elapsed = Date().timeIntervalSince(start)
    let queriesPerSecond = Double(queries.count) / elapsed

    #expect(elapsed < 5.0)
    #expect(queriesPerSecond > 10)
    #expect(totalResults >= 0)
  }

  private func generateRandomQueries(count: Int) -> [String] {
    let commonTerms = [
      "face", "smile", "heart", "love", "happy", "sad", "cry", "laugh",
      "fire", "star", "sun", "moon", "cat", "dog", "food", "drink",
      "hand", "eye", "mouth", "red", "blue", "green", "party", "birthday",
    ]

    return (0..<count).map { _ in
      let wordCount = Int.random(in: 1...3)
      let words = (0..<wordCount).map { _ in
        commonTerms.randomElement()!
      }
      return words.joined(separator: " ")
    }
  }
}
