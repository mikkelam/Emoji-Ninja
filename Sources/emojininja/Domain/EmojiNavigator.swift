import Foundation
import ninjalib

@MainActor
struct EmojiNavigator {
  private(set) var state = EmojiNavigationState()

  mutating func move(
    action: EmojiNavigationAction,
    totalEmojis: Int,
    columns: Int,
    sectionCounts: [Int]
  ) -> [EmojiNavigationEffect] {
    EmojiNavigationReducer.reduce(
      state: &state,
      action: action,
      totalEmojis: totalEmojis,
      columns: columns,
      sectionCounts: sectionCounts
    )
  }

  mutating func resetWithoutScroll(totalEmojis: Int, columns: Int) -> [EmojiNavigationEffect] {
    EmojiNavigationReducer.reduce(
      state: &state,
      action: .resetSelectionWithoutScroll,
      totalEmojis: max(totalEmojis, 1),
      columns: columns
    )
  }

  mutating func resetAndScroll(totalEmojis: Int, columns: Int) -> [EmojiNavigationEffect] {
    EmojiNavigationReducer.reduce(
      state: &state,
      action: .resetSelectionAndScroll,
      totalEmojis: max(totalEmojis, 1),
      columns: columns
    )
  }
}
