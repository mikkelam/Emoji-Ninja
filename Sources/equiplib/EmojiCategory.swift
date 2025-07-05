import Foundation

public enum EmojiCategory: String, CaseIterable {
    case smileysAndEmotion = "smileysAndEmotion"
    case peopleAndBody = "peopleAndBody"
    case animalsAndNature = "animalsAndNature"
    case foodAndDrink = "foodAndDrink"
    case travelAndPlaces = "travelAndPlaces"
    case activities = "activities"
    case objects = "objects"
    case symbols = "symbols"
    case flags = "flags"

    public var name: String {
        switch self {
        case .smileysAndEmotion:
            return "Smileys & Emotion"
        case .peopleAndBody:
            return "People & Body"
        case .animalsAndNature:
            return "Animals & Nature"
        case .foodAndDrink:
            return "Food & Drink"
        case .travelAndPlaces:
            return "Travel & Places"
        case .activities:
            return "Activities"
        case .objects:
            return "Objects"
        case .symbols:
            return "Symbols"
        case .flags:
            return "Flags"
        }
    }

    public var icon: String {
        switch self {
        case .smileysAndEmotion:
            return "😀"
        case .peopleAndBody:
            return "👋"
        case .animalsAndNature:
            return "🐱"
        case .foodAndDrink:
            return "🍎"
        case .travelAndPlaces:
            return "🚗"
        case .activities:
            return "⚽"
        case .objects:
            return "💡"
        case .symbols:
            return "❤️"
        case .flags:
            return "🏳️"
        }
    }

    public var group: EmojiGroup {
        switch self {
        case .smileysAndEmotion:
            return .smileysAndEmotion
        case .peopleAndBody:
            return .peopleAndBody
        case .animalsAndNature:
            return .animalsAndNature
        case .foodAndDrink:
            return .foodAndDrink
        case .travelAndPlaces:
            return .travelAndPlaces
        case .activities:
            return .activities
        case .objects:
            return .objects
        case .symbols:
            return .symbols
        case .flags:
            return .flags
        }
    }

    var emojis: [EmojibaseEmoji] {
        return EmojiDataManager.shared.getEmojis(for: group)
    }

    var emojiCount: Int {
        return emojis.count
    }
}

// MARK: - Extensions for convenience
extension EmojiCategory {
    static var allEmojis: [EmojibaseEmoji] {
        return EmojiDataManager.shared.getAllEmojis()
    }

    static var availableCategories: [EmojiCategory] {
        return allCases.filter { !$0.emojis.isEmpty }
    }

    static func searchEmojis(query: String) -> [EmojibaseEmoji] {
        return EmojiDataManager.shared.searchEmojis(query: query)
    }

    func filteredEmojis(searchQuery: String) -> [EmojibaseEmoji] {
        guard !searchQuery.isEmpty else { return emojis }

        // Use the regular search which internally uses SearchKit when on MainActor
        let allResults = EmojiDataManager.shared.searchEmojis(query: searchQuery)

        // Filter to only include emojis from this category
        let categoryEmojisSet = Set(emojis.map { $0.hexcode })
        return allResults.filter { categoryEmojisSet.contains($0.hexcode) }
    }
}

// MARK: - Hashable conformance for SwiftUI
extension EmojiCategory: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
