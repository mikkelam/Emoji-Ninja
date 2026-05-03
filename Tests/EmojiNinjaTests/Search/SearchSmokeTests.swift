import Testing

@testable import ninjalib

struct SearchSmokeTests {

  var dataManager: EmojiDataManager {
    EmojiDataManager.shared
  }

  @Test @MainActor func commonQueriesFindExpectedEmojis() throws {
    let cases: [(query: String, expectedHexcode: String)] = [
      ("cowboy", "1F920"),
      ("cow", "1F404"),
      ("rocket", "1F680"),
      ("fire", "1F525"),
      ("heart", "2764"),
      ("dog", "1F436"),
      ("cat", "1F431"),
      ("pizza", "1F355"),
      ("party", "1F389"),
      ("laugh", "1F602"),
      ("thumbs up", "1F44D"),
      ("police", "1F46E"),
      ("doctor", "1F9D1-200D-2695-FE0F"),
      ("coffee", "2615"),
      ("soccer", "26BD"),
      ("book", "1F4DA"),
      ("apple", "1F34E"),
      ("star", "2B50"),
      ("sun", "2600"),
      ("moon", "1F319"),
    ]

    for testCase in cases {
      let results = dataManager.searchEmojisWithSearchKit(query: testCase.query)
      let topResults = Array(results.prefix(30))
      let found = topResults.contains { $0.hexcode == testCase.expectedHexcode }
      #expect(found, "query='\(testCase.query)' expectedHex='\(testCase.expectedHexcode)'")
    }
  }
}
