import SwiftUI
import ninjalib

struct CategoryFilterView: View {
  @Binding var selectedCategory: CategoryType?
  @Environment(\.theme) private var theme
  @StateObject private var frequentlyUsedManager = FrequentlyUsedEmojiManager.shared

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: theme.spacing.medium) {
          // All categories button
          CategoryPill(
            title: "All",
            emoji: "🥷",
            isSelected: selectedCategory == nil,
            action: { selectedCategory = nil }
          )
          .id("category_all")

          // Frequently used pill (only show if there are frequently used emojis)
          if frequentlyUsedManager.hasFrequentlyUsedEmojis() {
            CategoryPill(
              title: "Frequently Used",
              emoji: "⭐",
              isSelected: selectedCategory == .frequentlyUsed,
              action: { selectedCategory = .frequentlyUsed }
            )
            .id("category_frequently_used")
          }

          // Individual category buttons
          ForEach(EmojiGroup.availableGroups, id: \.self) { category in
            CategoryPill(
              title: category.name,
              emoji: category.representativeEmoji,
              isSelected: selectedCategory == .regular(category),
              action: { selectedCategory = .regular(category) }
            )
            .id("category_\(category.rawValue)")
          }
        }
        .padding(.horizontal, theme.spacing.medium)
      }
      .padding(.vertical, theme.spacing.small)
      .onChange(of: selectedCategory) { _, newCategory in
        withAnimation(.easeInOut(duration: 0.3)) {
          if let category = newCategory {
            switch category {
            case .frequentlyUsed:
              proxy.scrollTo("category_frequently_used", anchor: .center)
            case .regular(let group):
              proxy.scrollTo("category_\(group.rawValue)", anchor: .center)
            }
          } else {
            proxy.scrollTo("category_all", anchor: .center)
          }
        }
      }
    }
  }
}
