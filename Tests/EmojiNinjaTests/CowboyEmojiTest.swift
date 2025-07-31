import AppKit
import Testing

@testable import ninjalib

struct CowboyEmojiTest {

  var dataManager: EmojiDataManager {
    EmojiDataManager.shared
  }

  @Test @MainActor func cowboyEmojiFoundInCowSearch() throws {
    let results = dataManager.searchEmojisWithSearchKit(query: "cow")

    let cowboyEmoji = results.first { $0.unicode == "🤠" }
    #expect(cowboyEmoji != nil)

    if let cowboy = cowboyEmoji {
      #expect(cowboy.label == "cowboy hat face")
      #expect(cowboy.hexcode == "1F920")
      #expect(cowboy.tags?.contains("cowboy") ?? false)
    }

    let actualCowEmoji = results.first { $0.unicode == "🐄" }
    #expect(actualCowEmoji != nil)

    let cowFaceEmoji = results.first { $0.unicode == "🐮" }
    #expect(cowFaceEmoji != nil)
  }

  @Test @MainActor func searchKitCowboySearch() throws {
    let results = dataManager.searchEmojisWithSearchKit(query: "cow")

    let cowboyEmoji = results.first { $0.unicode == "🤠" }
    #expect(cowboyEmoji != nil)
  }

  @Test @MainActor func cowboyEmojiDirectSearch() throws {
    let results = dataManager.searchEmojisWithSearchKit(query: "cowboy")

    let cowboyEmoji = results.first { $0.unicode == "🤠" }
    #expect(cowboyEmoji != nil)
  }

  @Test func cowboyEmojiSupportChecker() throws {
    let cowboyUnicode = "🤠"

    let systemFont = NSFont.systemFont(ofSize: 16)
    let attributes: [NSAttributedString.Key: Any] = [.font: systemFont]
    let attributedString = NSAttributedString(string: cowboyUnicode, attributes: attributes)
    let size = attributedString.size()

    let wouldPass = size.width > 5 && size.height > 5
    #expect(wouldPass)

    let allEmojis = dataManager.getAllEmojis()
    let cowboyEmoji = allEmojis.first { $0.unicode == cowboyUnicode }
    #expect(cowboyEmoji != nil)
  }
}
