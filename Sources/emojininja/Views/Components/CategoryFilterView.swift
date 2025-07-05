import SwiftUI
import ninjalib

struct CategoryFilterView: View {
    @Binding var selectedCategory: CategoryType?
    @Environment(\.theme) private var theme
    @StateObject private var frequentlyUsedManager = FrequentlyUsedEmojiManager.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.medium) {
                // All categories button
                CategoryPill(
                    title: "All",
                    emoji: "🏷️",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                // Frequently used pill (only show if there are frequently used emojis)
                if frequentlyUsedManager.hasFrequentlyUsedEmojis() {
                    CategoryPill(
                        title: "Frequently Used",
                        emoji: "⭐",
                        isSelected: selectedCategory == .frequentlyUsed,
                        action: { selectedCategory = .frequentlyUsed }
                    )
                }

                // Individual category buttons
                ForEach(EmojiGroup.availableGroups, id: \.self) { category in
                    CategoryPill(
                        title: category.name,
                        emoji: category.representativeEmoji,
                        isSelected: selectedCategory == .regular(category),
                        action: { selectedCategory = .regular(category) }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.medium)
        }
        .padding(.vertical, theme.spacing.small)
    }
}
