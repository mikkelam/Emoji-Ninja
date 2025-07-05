import SwiftUI
import equiplib

struct EmojiGridView: View {
    let geometry: GeometryProxy
    let selectedEmojiIndex: Int
    let selectedCategory: CategoryType?
    let onEmojiSelected: (String) -> Void
    @ObservedObject var emojiManager: EmojiManager
    @ObservedObject var viewModel: EmojiPickerViewModel
    @Environment(\.theme) private var theme

    private var adaptiveColumns: [GridItem] {
        Array(
            repeating: GridItem(.adaptive(minimum: 60, maximum: 120), spacing: theme.spacing.small),
            count: 8)
    }

    private var emojiData:
        [(category: CategoryType, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)])]
    {
        let allCategories = CategoryType.availableCategories
        let categories =
            viewModel.selectedCategory != nil ? [viewModel.selectedCategory!] : allCategories

        var globalIndex = 0

        let result = categories.compactMap {
            category -> (
                category: CategoryType, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)]
            )? in
            let emojis = category.getEmojis()
            guard !emojis.isEmpty else { return nil }

            let emojiIndices = emojis.map { emoji in
                let result = (emoji: emoji, globalIndex: globalIndex)
                globalIndex += 1
                return result
            }

            return (category: category, emojiIndices: emojiIndices)
        }

        return result
    }

    var body: some View {
        ForEach(emojiData, id: \.category) { categoryData in
            Section {
                LazyVGrid(columns: adaptiveColumns, spacing: theme.spacing.small) {
                    ForEach(categoryData.emojiIndices, id: \.globalIndex) { emojiData in
                        EmojiButton(
                            emoji: emojiData.emoji.unicode,
                            isSelected: emojiData.globalIndex == selectedEmojiIndex,
                            geometry: geometry
                        ) {
                            onEmojiSelected(emojiData.emoji.unicode)
                        }
                        .id(
                            "emoji_\(emojiData.globalIndex)_\(viewModel.selectedCategory?.hashValue ?? -1)"
                        )
                    }
                }
                .id("grid_\(categoryData.category)_\(categoryData.emojiIndices.count)")
            } header: {
                HStack {
                    Text(categoryData.category.displayName)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.text.primary)
                    Spacer()
                }
                .padding(.bottom, 2)
                .padding(
                    .top,
                    categoryData.category == CategoryType.availableCategories.first
                        ? 0 : theme.spacing.medium)
            }
            .id(categoryData.category)
        }
        .id("category_grid_\(viewModel.selectedCategory?.hashValue ?? -1)_\(emojiData.count)")
    }
}
