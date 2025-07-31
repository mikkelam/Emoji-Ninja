import SwiftUI
import ninjalib

struct EmojiGridView: View {
  let geometry: GeometryProxy
  let selectedEmojiIndex: Int
  let selectedCategory: CategoryType?
  let onEmojiSelected: (EmojibaseEmoji) -> Void
  @ObservedObject var emojiManager: EmojiManager
  @ObservedObject var viewModel: EmojiPickerViewModel
  @Environment(\.theme) private var theme

  private var buttonSize: CGFloat {
    EmojiLayout.cachedButtonSize(for: geometry, theme: theme)
  }

  private var adaptiveColumns: [GridItem] {
    Array(
      repeating: GridItem(.adaptive(minimum: 60, maximum: 120), spacing: theme.spacing.small),
      count: EmojiLayout.gridColumns)
  }

  private var emojiData:
    [(category: CategoryType, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)])]
  {
    let allCategories = CategoryType.availableCategories
    let categories =
      viewModel.selectedCategory != nil ? [viewModel.selectedCategory!] : allCategories

    var globalIndex = 0
    return categories.compactMap { category in
      let emojis = category.getEmojis()
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
    ForEach(emojiData, id: \.category) { categoryData in
      EmojiCategorySection(
        categoryData: categoryData,
        adaptiveColumns: adaptiveColumns,
        selectedEmojiIndex: selectedEmojiIndex,
        buttonSize: buttonSize,
        onEmojiSelected: onEmojiSelected
      )
    }
    .id("category_grid_\(viewModel.selectedCategory?.hashValue ?? -1)")
  }
}

struct EmojiCategorySection: View {
  let categoryData:
    (category: CategoryType, emojiIndices: [(emoji: EmojibaseEmoji, globalIndex: Int)])
  let adaptiveColumns: [GridItem]
  let selectedEmojiIndex: Int
  let buttonSize: CGFloat
  let onEmojiSelected: (EmojibaseEmoji) -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Section {
      LazyVGrid(columns: adaptiveColumns, spacing: theme.spacing.small) {
        ForEach(categoryData.emojiIndices, id: \.globalIndex) { emojiIndexData in
          FastEmojiButton(
            emojiData: emojiIndexData.emoji,
            isSelected: emojiIndexData.globalIndex == selectedEmojiIndex,
            buttonSize: buttonSize
          ) {
            onEmojiSelected(emojiIndexData.emoji)
          }
          .id("emoji_\(emojiIndexData.emoji.hexcode)")
        }
      }
      .id("grid_\(categoryData.category)")
    } header: {
      EmojiCategoryHeader(category: categoryData.category)
    }
    .id(categoryData.category)
  }
}

struct EmojiCategoryHeader: View {
  let category: CategoryType
  @Environment(\.theme) private var theme

  var body: some View {
    HStack {
      Text(category.representativeEmoji)
        .font(.title3)
      Text(category.displayName)
        .font(theme.typography.headline)
        .foregroundColor(theme.colors.text.secondary)
      Spacer()
    }
    .padding(.bottom, 2)
    .padding(
      .top,
      category == CategoryType.availableCategories.first ? 0 : theme.spacing.medium
    )
  }
}
