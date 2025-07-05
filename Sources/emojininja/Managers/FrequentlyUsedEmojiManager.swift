import Foundation
import ninjalib

@MainActor
class FrequentlyUsedEmojiManager: ObservableObject {
    static let shared = FrequentlyUsedEmojiManager()

    @Published var frequentlyUsedEmojis: [EmojibaseEmoji] = []

    private let userDefaults = UserDefaults.standard
    private let usageCountKey = "emojiUsageCount"
    private let maxFrequentEmojis = 16

    private var emojiUsageCount: [String: Int] = [:]

    private init() {
        loadUsageData()
        updateFrequentlyUsedEmojis()
    }

    func recordEmojiUsage(_ emoji: String) {
        emojiUsageCount[emoji, default: 0] += 1
        saveUsageData()
        updateFrequentlyUsedEmojis()
    }

    func clearUsageData() {
        emojiUsageCount.removeAll()
        frequentlyUsedEmojis.removeAll()
        userDefaults.removeObject(forKey: usageCountKey)
    }

    func getFrequentlyUsedEmojis() -> [EmojibaseEmoji] {
        return frequentlyUsedEmojis
    }

    func hasFrequentlyUsedEmojis() -> Bool {
        return !frequentlyUsedEmojis.isEmpty
    }

    private func loadUsageData() {
        if let data = userDefaults.data(forKey: usageCountKey),
            let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        {
            emojiUsageCount = decoded
        }
    }

    private func saveUsageData() {
        if let encoded = try? JSONEncoder().encode(emojiUsageCount) {
            userDefaults.set(encoded, forKey: usageCountKey)
        }
    }

    private func updateFrequentlyUsedEmojis() {
        let sortedEmojis =
            emojiUsageCount
            .sorted { $0.value > $1.value }
            .prefix(maxFrequentEmojis)
            .compactMap { (unicode, _) in
                AppEmojiManager.shared.getAllEmojis().first { $0.unicode == unicode }
            }

        frequentlyUsedEmojis = Array(sortedEmojis)
    }
}
