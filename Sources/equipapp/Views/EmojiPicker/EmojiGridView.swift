import SwiftUI
import equiplib

struct EmojiGridView: View {
    let geometry: GeometryProxy
    let selectedEmojiIndex: Int
    let selectedCategory: EmojiGroup?
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
        [(category: EmojiGroup, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)])]
    {
        let allCategories = EmojiGroup.availableGroups
        let categories =
            viewModel.selectedCategory != nil ? [viewModel.selectedCategory!] : allCategories

        var globalIndex = 0
        let result = categories.compactMap {
            category -> (
                category: EmojiGroup, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)]
            )? in
            let emojis = AppEmojiManager.shared.getEmojis(for: category)
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
        ForEach(emojiData, id: \.category.rawValue) { categoryData in
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
                            "emoji_\(emojiData.globalIndex)_\(viewModel.selectedCategory?.rawValue ?? -1)"
                        )
                    }
                }
                .id("grid_\(categoryData.category.rawValue)_\(categoryData.emojiIndices.count)")
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
                    categoryData.category == EmojiGroup.availableGroups.first
                        ? 0 : theme.spacing.medium)
            }
            .id(categoryData.category.rawValue)
        }
        .id("category_grid_\(viewModel.selectedCategory?.rawValue ?? -1)_\(emojiData.count)")
    }
}
