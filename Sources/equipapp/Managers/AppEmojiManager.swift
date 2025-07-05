import Foundation
import equiplib

/// App-level emoji manager that adds platform-specific filtering
@MainActor
class AppEmojiManager {
    static let shared = AppEmojiManager()

    private let dataManager = EmojiDataManager.shared
    private var supportedEmojis: [EmojibaseEmoji] = []
    private var supportedEmojisByGroup: [Int: [EmojibaseEmoji]] = [:]

    private init() {
        loadSupportedEmojis()
    }

    private func loadSupportedEmojis() {
        // Get all useful emojis from the library
        let allUsefulEmojis = dataManager.getAllEmojis()

        // Filter by platform support
        supportedEmojis = allUsefulEmojis.filter { emoji in
            emoji.isSupported
        }

        print("✅ \(supportedEmojis.count) emojis supported on this platform")

        // Group supported emojis
        supportedEmojisByGroup = Dictionary(grouping: supportedEmojis) { emoji in
            emoji.group ?? 0
        }
    }

    // MARK: - Public API

    func getAllEmojis() -> [EmojibaseEmoji] {
        return supportedEmojis
    }

    func getEmojis(for group: EmojiGroup) -> [EmojibaseEmoji] {
        return supportedEmojisByGroup[group.rawValue] ?? []
    }

    func searchEmojis(query: String) -> [EmojibaseEmoji] {
        guard !query.isEmpty else { return [] }

        // Use the library's search but filter by support
        let searchResults = dataManager.searchEmojis(query: query)
        return searchResults.filter { $0.isSupported }
    }

    @MainActor
    func searchEmojisWithSearchKit(query: String) -> [EmojibaseEmoji] {
        let results = dataManager.searchEmojisWithSearchKit(query: query)
        return results.filter { $0.isSupported }
    }

    func getAvailableGroups() -> [EmojiGroup] {
        return EmojiGroup.allCases.filter { group in
            !getEmojis(for: group).isEmpty
        }
    }
}
