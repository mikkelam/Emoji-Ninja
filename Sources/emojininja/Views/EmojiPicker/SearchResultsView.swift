import SwiftUI
import ninjalib

struct SearchResultsView: View {
    let geometry: GeometryProxy
    let searchResults: [EmojibaseEmoji]
    let selectedEmojiIndex: Int
    let searchResultsId: UUID
    let onEmojiSelected: (EmojibaseEmoji) -> Void
    @Environment(\.theme) private var theme

    private var adaptiveColumns: [GridItem] {
        Array(
            repeating: GridItem(.adaptive(minimum: 60, maximum: 120), spacing: theme.spacing.small),
            count: 8)
    }

    var body: some View {
        Group {
            if searchResults.isEmpty {
                VStack(spacing: theme.spacing.medium) {
                    Image(systemName: "magnifyingglass")
                        .iconStyle(color: .secondary, size: .extraLarge)

                    Text("No emojis found")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.text.secondary)

                    Text("Try searching for something else")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.text.secondary)
                }
                .emptyStateStyle()
            } else {
                LazyVGrid(columns: adaptiveColumns, spacing: theme.spacing.small) {
                    ForEach(Array(searchResults.enumerated()), id: \.element.hexcode) {
                        index, emoji in
                        EmojiButton(
                            emojiData: emoji,
                            isSelected: index == selectedEmojiIndex,
                            geometry: geometry
                        ) {
                            onEmojiSelected(emoji)
                        }
                        .id("emoji_\(emoji.hexcode)")
                    }
                }
                .id("search_grid_\(searchResultsId)")
            }
        }
    }
}
