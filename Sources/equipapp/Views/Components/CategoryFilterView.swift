import SwiftUI
import equiplib

struct CategoryFilterView: View {
    @Binding var selectedCategory: EmojiGroup?
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.small) {
                // All categories button
                CategoryPill(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                // Individual category buttons
                ForEach(EmojiGroup.availableGroups, id: \.self) { category in
                    CategoryPill(
                        title: category.name,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.medium)
        }
        .padding(.vertical, theme.spacing.small)
    }
}
