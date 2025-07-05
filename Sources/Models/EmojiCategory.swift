import EmojiKit
import Foundation

enum EmojiCategory: String, CaseIterable {
    case smileysAndPeople = "smileysAndPeople"
    case animalsAndNature = "animalsAndNature"
    case foodAndDrink = "foodAndDrink"
    case activity = "activity"
    case travelAndPlaces = "travelAndPlaces"
    case objects = "objects"
    case symbols = "symbols"
    case flags = "flags"

    var name: String {
        switch self {
        case .smileysAndPeople:
            return "Smileys & People"
        case .animalsAndNature:
            return "Animals & Nature"
        case .foodAndDrink:
            return "Food & Drink"
        case .activity:
            return "Activity"
        case .travelAndPlaces:
            return "Travel & Places"
        case .objects:
            return "Objects"
        case .symbols:
            return "Symbols"
        case .flags:
            return "Flags"
        }
    }

    var icon: String {
        switch self {
        case .smileysAndPeople:
            return "😀"
        case .animalsAndNature:
            return "🐱"
        case .foodAndDrink:
            return "🍎"
        case .activity:
            return "⚽"
        case .travelAndPlaces:
            return "🚗"
        case .objects:
            return "💡"
        case .symbols:
            return "❤️"
        case .flags:
            return "🏳️"
        }
    }

    var emojis: [Emoji] {
        switch self {
        case .smileysAndPeople:
            return EmojiKit.EmojiCategory.smileysAndPeople.emojis
        case .animalsAndNature:
            return EmojiKit.EmojiCategory.animalsAndNature.emojis
        case .foodAndDrink:
            return EmojiKit.EmojiCategory.foodAndDrink.emojis
        case .activity:
            return EmojiKit.EmojiCategory.activity.emojis
        case .travelAndPlaces:
            return EmojiKit.EmojiCategory.travelAndPlaces.emojis
        case .objects:
            return EmojiKit.EmojiCategory.objects.emojis
        case .symbols:
            return EmojiKit.EmojiCategory.symbols.emojis
        case .flags:
            return EmojiKit.EmojiCategory.flags.emojis
        }
    }

    var emojiCount: Int {
        return emojis.count
    }
}

// MARK: - Extensions for convenience
extension EmojiCategory {
    static var allEmojis: [Emoji] {
        return allCases.flatMap { $0.emojis }
    }

    static func searchEmojis(query: String) -> [Emoji] {
        guard !query.isEmpty else { return [] }

        let lowercasedQuery = query.lowercased()
        var results: [Emoji] = []

        for category in allCases {
            let categoryResults = category.emojis.filter { emoji in
                emoji.localizedName.lowercased().contains(lowercasedQuery)
                    || emoji.unicodeName.lowercased().contains(lowercasedQuery)
            }
            results.append(contentsOf: categoryResults)
        }

        return results
    }

    func filteredEmojis(searchQuery: String) -> [Emoji] {
        guard !searchQuery.isEmpty else { return emojis }

        let lowercasedQuery = searchQuery.lowercased()
        return emojis.filter { emoji in
            emoji.localizedName.lowercased().contains(lowercasedQuery)
                || emoji.unicodeName.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - Hashable conformance for SwiftUI
extension EmojiCategory: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
