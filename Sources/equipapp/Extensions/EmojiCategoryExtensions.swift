import Foundation
import equiplib

// MARK: - App-specific EmojiCategory Extensions

extension EmojiCategory {
    /// Get all emojis for this category, filtered by platform support
    @MainActor
    var emojis: [EmojibaseEmoji] {
        return AppEmojiManager.shared.getEmojis(for: self.group)
    }

    /// Get available categories that have supported emojis
    @MainActor
    static var availableCategories: [EmojiCategory] {
        return allCases.filter { category in
            !AppEmojiManager.shared.getEmojis(for: category.group).isEmpty
        }
    }

    /// Search emojis with platform support filtering
    @MainActor
    static func searchEmojis(query: String) -> [EmojibaseEmoji] {
        return AppEmojiManager.shared.searchEmojis(query: query)
    }

    /// Filter emojis within this category by search query
    @MainActor
    func filteredEmojis(searchQuery: String) -> [EmojibaseEmoji] {
        guard !searchQuery.isEmpty else { return emojis }

        // Use AppEmojiManager's search and filter to only include emojis from this category
        let allResults = AppEmojiManager.shared.searchEmojis(query: searchQuery)
        let categoryEmojisSet = Set(emojis.map { $0.hexcode })
        return allResults.filter { categoryEmojisSet.contains($0.hexcode) }
    }
}
