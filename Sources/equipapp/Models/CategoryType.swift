import Foundation
import equiplib

/// Special category types that extend beyond regular EmojiGroup categories
@MainActor
enum CategoryType: Hashable {
    case frequentlyUsed
    case regular(EmojiGroup)

    var displayName: String {
        switch self {
        case .frequentlyUsed:
            return "Frequently Used"
        case .regular(let group):
            return group.name
        }
    }

    var representativeEmoji: String {
        switch self {
        case .frequentlyUsed:
            return "⭐"
        case .regular(let group):
            return group.representativeEmoji
        }
    }

    var isAvailable: Bool {
        switch self {
        case .frequentlyUsed:
            return FrequentlyUsedEmojiManager.shared.hasFrequentlyUsedEmojis()
        case .regular(let group):
            return !AppEmojiManager.shared.getEmojis(for: group).isEmpty
        }
    }

    func getEmojis() -> [EmojibaseEmoji] {
        switch self {
        case .frequentlyUsed:
            return FrequentlyUsedEmojiManager.shared.getFrequentlyUsedEmojis()
        case .regular(let group):
            return AppEmojiManager.shared.getEmojis(for: group)
        }
    }

    static var availableCategories: [CategoryType] {
        var categories: [CategoryType] = []

        // Add frequently used if available
        if FrequentlyUsedEmojiManager.shared.hasFrequentlyUsedEmojis() {
            categories.append(.frequentlyUsed)
        }

        // Add regular categories
        categories.append(contentsOf: EmojiGroup.availableGroups.map { .regular($0) })

        return categories
    }
}
