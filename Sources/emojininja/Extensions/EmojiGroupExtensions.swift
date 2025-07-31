import Foundation
import ninjalib

// MARK: - App-specific EmojiGroup Extensions

extension EmojiGroup {
  /// Get all emojis for this group, filtered by platform support
  @MainActor
  var emojis: [EmojibaseEmoji] {
    return AppEmojiManager.shared.getEmojis(for: self)
  }

  /// Get available groups that have supported emojis
  @MainActor
  static var availableGroups: [EmojiGroup] {
    return allCases.filter { group in
      !AppEmojiManager.shared.getEmojis(for: group).isEmpty
        && group.name.lowercased() != "components"
    }
  }

  /// Search emojis with platform support filtering
  @MainActor
  static func searchEmojis(query: String) -> [EmojibaseEmoji] {
    return AppEmojiManager.shared.searchEmojisWithSearchKit(query: query)
  }

  /// Filter emojis within this group by search query
  @MainActor
  func filteredEmojis(searchQuery: String) -> [EmojibaseEmoji] {
    guard !searchQuery.isEmpty else { return emojis }

    // Use AppEmojiManager's SearchKit search and filter to only include emojis from this group
    let allResults = AppEmojiManager.shared.searchEmojisWithSearchKit(query: searchQuery)
    let groupEmojisSet = Set(emojis.map { $0.hexcode })
    return allResults.filter { groupEmojisSet.contains($0.hexcode) }
  }
}
