import Foundation

// MARK: - Emojibase Data Models

public struct EmojibaseEmoji: Codable {
    public let hexcode: String
    public let label: String
    public let unicode: String
    public let group: Int?
    public let order: Int?
    public let tags: [String]?
    public let emoticon: EmojibaseEmoticon?
    public let skins: [EmojibaseEmoji]?
    public let supportsSkinTones: Bool

    enum CodingKeys: String, CodingKey {
        case hexcode, label, unicode, group, order, tags, emoticon, skins
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hexcode = try container.decode(String.self, forKey: .hexcode)
        label = try container.decode(String.self, forKey: .label)
        unicode = try container.decode(String.self, forKey: .unicode)
        group = try container.decodeIfPresent(Int.self, forKey: .group)
        order = try container.decodeIfPresent(Int.self, forKey: .order)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        skins = try container.decodeIfPresent([EmojibaseEmoji].self, forKey: .skins)
        supportsSkinTones = skins != nil

        // Handle emoticon which can be either String or [String]
        if let singleEmoticon = try? container.decode(String.self, forKey: .emoticon) {
            emoticon = .single(singleEmoticon)
        } else if let multipleEmoticons = try? container.decode([String].self, forKey: .emoticon) {
            emoticon = .multiple(multipleEmoticons)
        } else {
            emoticon = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hexcode, forKey: .hexcode)
        try container.encode(label, forKey: .label)
        try container.encode(unicode, forKey: .unicode)
        try container.encodeIfPresent(group, forKey: .group)
        try container.encodeIfPresent(order, forKey: .order)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(skins, forKey: .skins)

        switch emoticon {
        case .single(let value):
            try container.encode(value, forKey: .emoticon)
        case .multiple(let values):
            try container.encode(values, forKey: .emoticon)
        case .none:
            break
        }
    }
}

public enum EmojibaseEmoticon: Codable {
    case single(String)
    case multiple([String])

    var values: [String] {
        switch self {
        case .single(let value):
            return [value]
        case .multiple(let values):
            return values
        }
    }
}

// MARK: - App's Emoji Categories (mapped from emojibase groups)

public enum EmojiGroup: Int, CaseIterable {
    case smileysAndEmotion = 0
    case peopleAndBody = 1
    case component = 2
    case animalsAndNature = 3
    case foodAndDrink = 4
    case travelAndPlaces = 5
    case activities = 6
    case objects = 7
    case symbols = 8
    case flags = 9

    public var name: String {
        switch self {
        case .smileysAndEmotion:
            return "Smileys & Emotion"
        case .peopleAndBody:
            return "People & Body"
        case .component:
            return "Components"
        case .animalsAndNature:
            return "Animals & Nature"
        case .foodAndDrink:
            return "Food & Drink"
        case .activities:
            return "Activities"
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

    public var representativeEmoji: String {
        switch self {
        case .smileysAndEmotion:
            return "😀"
        case .peopleAndBody:
            return "👋"
        case .component:
            return "🔧"
        case .animalsAndNature:
            return "🐱"
        case .foodAndDrink:
            return "🍕"
        case .activities:
            return "🎨"
        case .travelAndPlaces:
            return "🚗"
        case .objects:
            return "👓️"
        case .symbols:
            return "☮️"
        case .flags:
            return "🏳️"
        }
    }

}

// MARK: - Emoji Font Support Checking

extension EmojibaseEmoji {

    var isUseful: Bool {
        // Filter out regional indicators (flag building blocks)
        if label.contains("regional indicator") {
            return false
        }

        // Filter out other non-useful emojis
        let unwantedLabels = [
            "skin tone",
            "hair component",
            "combining",
            "modifier",
            "variation selector",
        ]

        return !unwantedLabels.contains { unwantedLabel in
            label.lowercased().contains(unwantedLabel)
        }
    }
}

// MARK: - Emoji Data Manager

public class EmojiDataManager {
    nonisolated(unsafe) public static let shared = EmojiDataManager()

    private var allEmojis: [EmojibaseEmoji] = []
    private var supportedEmojis: [EmojibaseEmoji] = []
    private var emojisByGroup: [Int: [EmojibaseEmoji]] = [:]

    private init() {
        loadEmojiData()
    }

    private func loadEmojiData() {
        guard let resourcePath = Bundle.main.resourcePath else {
            fatalError("❌ Failed to find app resources path")
        }

        let bundlePath = URL(fileURLWithPath: resourcePath).appendingPathComponent(
            "Emoji Ninja_ninjalib.bundle")

        guard let resourceBundle = Bundle(url: bundlePath) else {
            fatalError("❌ Failed to load resource bundle at \(bundlePath)")
        }

        guard let url = resourceBundle.url(forResource: "emoji_data", withExtension: "json") else {
            fatalError("❌ Failed to find emoji_data.json in resource bundle")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("❌ Failed to load data from emoji_data.json")
        }

        do {
            allEmojis = try JSONDecoder().decode([EmojibaseEmoji].self, from: data)
            print("✅ Loaded \(allEmojis.count) emojis")

            // Filter useful emojis
            supportedEmojis = allEmojis.filter { $0.isUseful }
            print("📱 \(supportedEmojis.count) useful emojis loaded")

            // Group emojis by category
            groupEmojis()

        } catch {
            fatalError("❌ Failed to decode emoji data: \(error)")
        }
    }

    private func groupEmojis() {
        emojisByGroup = Dictionary(grouping: supportedEmojis) { emoji in
            emoji.group ?? 0
        }
    }

    // MARK: - Public API

    public func getAllEmojis() -> [EmojibaseEmoji] {
        return supportedEmojis
    }

    func getSupportedEmojis() -> [EmojibaseEmoji] {
        return supportedEmojis
    }

    public func getEmojis(for group: EmojiGroup) -> [EmojibaseEmoji] {
        return emojisByGroup[group.rawValue] ?? []
    }

    func getAvailableGroups() -> [EmojiGroup] {
        return EmojiGroup.allCases.filter { group in
            !getEmojis(for: group).isEmpty
        }
    }
}

// MARK: - Skin Tone Support

extension EmojibaseEmoji {

    public func withSkinTone(_ skinTone: SkinTone) -> String {
        guard skinTone != .default, let modifier = skinTone.modifier else {
            return self.unicode
        }

        // If emoji has skin tone variations, compose directly
        if supportsSkinTones {
            return self.unicode + String(UnicodeScalar(Int(modifier, radix: 16)!)!)
        }

        // Fallback to original emoji if no skin tone variations available
        return self.unicode
    }
}
