import SwiftUI
import equiplib

struct EmojiGridView: View {
    let geometry: GeometryProxy
    let selectedEmojiIndex: Int
    let selectedCategory: EmojiCategory?
    let onEmojiSelected: (String) -> Void
    @ObservedObject var emojiManager: EmojiManager
    @Environment(\.theme) private var theme

    private var adaptiveColumns: [GridItem] {
        Array(
            repeating: GridItem(.adaptive(minimum: 60, maximum: 120), spacing: theme.spacing.small),
            count: 8)
    }

    private var emojiDataWithIndices:
        [(category: EmojiCategory, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)])]
    {
        let categories =
            selectedCategory != nil ? [selectedCategory!] : EmojiCategory.availableCategories
        var globalIndex = 0

        return categories.compactMap { category in
            let emojis = category.emojis
            guard !emojis.isEmpty else { return nil }

            let emojiIndices = emojis.map { emoji in
                let result = (emoji: emoji, globalIndex: globalIndex)
                globalIndex += 1
                return result
            }

            return (category: category, emojiIndices: emojiIndices)
        }
    }

    var body: some View {
        ForEach(emojiDataWithIndices, id: \.category.rawValue) { categoryData in
            Section {
                LazyVGrid(columns: adaptiveColumns, spacing: theme.spacing.small) {
                    ForEach(categoryData.emojiIndices, id: \.emoji.unicode) { emojiData in
                        EmojiButton(
                            emoji: emojiData.emoji.unicode,
                            isSelected: emojiData.globalIndex == selectedEmojiIndex,
                            geometry: geometry
                        ) {
                            onEmojiSelected(emojiData.emoji.unicode)
                        }
                        .id("emoji_\(emojiData.globalIndex)")
                    }
                }
            } header: {
                HStack {
                    Text(categoryData.category.name)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.text.primary)
                    Spacer()
                }
                .padding(.bottom, 2)
                .padding(
                    .top,
                    categoryData.category == EmojiCategory.availableCategories.first
                        ? 0 : theme.spacing.medium)
            }
        }
    }
}
