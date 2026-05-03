import Foundation
import ninjalib

@MainActor
protocol EmojiRepository {
  func emojis(for group: EmojiGroup) -> [EmojibaseEmoji]
  func availableGroups() -> [EmojiGroup]
  func search(query: String) -> [EmojibaseEmoji]
  func frequentlyUsedEmojis() -> [EmojibaseEmoji]
  func hasFrequentlyUsedEmojis() -> Bool
}

@MainActor
struct DefaultEmojiRepository: EmojiRepository {
  func emojis(for group: EmojiGroup) -> [EmojibaseEmoji] {
    AppEmojiManager.shared.getEmojis(for: group)
  }

  func availableGroups() -> [EmojiGroup] {
    AppEmojiManager.shared.getAvailableGroups()
  }

  func search(query: String) -> [EmojibaseEmoji] {
    AppEmojiManager.shared.searchEmojisWithSearchKit(query: query)
  }

  func frequentlyUsedEmojis() -> [EmojibaseEmoji] {
    FrequentlyUsedEmojiManager.shared.getFrequentlyUsedEmojis()
  }

  func hasFrequentlyUsedEmojis() -> Bool {
    FrequentlyUsedEmojiManager.shared.hasFrequentlyUsedEmojis()
  }
}
