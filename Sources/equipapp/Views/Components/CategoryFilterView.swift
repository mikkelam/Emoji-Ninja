import SwiftUI
import equiplib

struct CategoryFilterView: View {
    @Binding var selectedCategory: CategoryType?
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
                ForEach(CategoryType.availableCategories, id: \.self) { category in
                    CategoryPill(
                        title: category.displayName,
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
