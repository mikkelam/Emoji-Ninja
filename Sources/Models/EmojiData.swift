import AppKit
import CoreText
import Foundation

// MARK: - Emojibase Data Models

struct EmojibaseEmoji: Codable {
    let hexcode: String
    let label: String
    let unicode: String
    let group: Int?
    let order: Int?
    let tags: [String]?
    let emoticon: EmojibaseEmoticon?

    enum CodingKeys: String, CodingKey {
        case hexcode, label, unicode, group, order, tags, emoticon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        hexcode = try container.decode(String.self, forKey: .hexcode)
        label = try container.decode(String.self, forKey: .label)
        unicode = try container.decode(String.self, forKey: .unicode)
        group = try container.decodeIfPresent(Int.self, forKey: .group)
        order = try container.decodeIfPresent(Int.self, forKey: .order)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)

        // Handle emoticon which can be either String or [String]
        if let singleEmoticon = try? container.decode(String.self, forKey: .emoticon) {
            emoticon = .single(singleEmoticon)
        } else if let multipleEmoticons = try? container.decode([String].self, forKey: .emoticon) {
            emoticon = .multiple(multipleEmoticons)
        } else {
            emoticon = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(hexcode, forKey: .hexcode)
        try container.encode(label, forKey: .label)
        try container.encode(unicode, forKey: .unicode)
        try container.encodeIfPresent(group, forKey: .group)
        try container.encodeIfPresent(order, forKey: .order)
        try container.encodeIfPresent(tags, forKey: .tags)

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

enum EmojibaseEmoticon: Codable {
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

enum EmojiGroup: Int, CaseIterable {
    case smileysAndEmotion = 0
    case peopleAndBody = 1
    case animalsAndNature = 2
    case foodAndDrink = 3
    case travelAndPlaces = 4
    case activities = 5
    case objects = 6
    case symbols = 7
    case flags = 8

    var name: String {
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

    var icon: String {
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
}

// MARK: - Emoji Font Support Checking

extension EmojibaseEmoji {
    var isSupported: Bool {
        return EmojiSupportChecker.isSupported(self.unicode)
    }

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

struct EmojiSupportChecker {
    nonisolated(unsafe) private static let cache = NSCache<NSString, NSNumber>()

    static func isSupported(_ emoji: String) -> Bool {
        let key = emoji as NSString

        if let cached = cache.object(forKey: key) {
            return cached.boolValue
        }

        let supported = checkEmojiSupport(emoji)
        cache.setObject(NSNumber(value: supported), forKey: key)
        return supported
    }

    private static func checkEmojiSupport(_ emoji: String) -> Bool {
        // Simple visual bounds checking
        let systemFont = NSFont.systemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [.font: systemFont]
        let attributedString = NSAttributedString(string: emoji, attributes: attributes)

        let size = attributedString.size()

        // If emoji is supported, it should have reasonable dimensions
        return size.width > 8 && size.height > 8
    }
}

// MARK: - Emoji Data Manager

class EmojiDataManager {
    nonisolated(unsafe) static let shared = EmojiDataManager()

    private var allEmojis: [EmojibaseEmoji] = []
    private var supportedEmojis: [EmojibaseEmoji] = []
    private var emojisByGroup: [Int: [EmojibaseEmoji]] = [:]

    private init() {
        loadEmojiData()
    }

    private func loadEmojiData() {
        // Try to find the bundle that contains our resources
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: "emoji_data", withExtension: "json") else {
            print("❌ Failed to find emoji_data.json in bundle")
            print("📦 Bundle path: \(bundle.bundlePath)")
            if let resourcePath = bundle.resourcePath {
                print("📁 Resource path: \(resourcePath)")
                let resourceURL = URL(fileURLWithPath: resourcePath)
                if let contents = try? FileManager.default.contentsOfDirectory(
                    at: resourceURL, includingPropertiesForKeys: nil)
                {
                    print("📋 Bundle contents: \(contents.map { $0.lastPathComponent })")
                }
            }
            return
        }

        guard let data = try? Data(contentsOf: url) else {
            print("❌ Failed to load data from emoji_data.json")
            return
        }

        do {
            allEmojis = try JSONDecoder().decode([EmojibaseEmoji].self, from: data)
            print("✅ Loaded \(allEmojis.count) emojis")

            // Filter supported and useful emojis
            supportedEmojis = allEmojis.filter { $0.isSupported && $0.isUseful }
            print("📱 \(supportedEmojis.count) useful emojis supported on this system")

            // Group emojis by category
            groupEmojis()

        } catch {
            print("❌ Failed to decode emoji data: \(error)")
        }
    }

    private func groupEmojis() {
        emojisByGroup = Dictionary(grouping: supportedEmojis) { emoji in
            emoji.group ?? 0
        }
    }

    // MARK: - Public API

    func getAllEmojis() -> [EmojibaseEmoji] {
        return supportedEmojis
    }

    func getEmojis(for group: EmojiGroup) -> [EmojibaseEmoji] {
        return emojisByGroup[group.rawValue] ?? []
    }

    func searchEmojis(query: String) -> [EmojibaseEmoji] {
        guard !query.isEmpty else { return [] }

        let lowercaseQuery = query.lowercased()

        return supportedEmojis.filter { emoji in
            // Search in label
            emoji.label.lowercased().contains(lowercaseQuery)
                // Search in tags
                || emoji.tags?.contains { tag in
                    tag.lowercased().contains(lowercaseQuery)
                } == true
                // Search in emoticons
                || emoji.emoticon?.values.contains { emoticon in
                    emoticon.lowercased().contains(lowercaseQuery)
                } == true
        }
    }

    func getAvailableGroups() -> [EmojiGroup] {
        return EmojiGroup.allCases.filter { group in
            !getEmojis(for: group).isEmpty
        }
    }
}
