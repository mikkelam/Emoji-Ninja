public struct EmojiNavigationState: Equatable {
  public var selectedEmojiIndex: Int

  public init(selectedEmojiIndex: Int = 0) {
    self.selectedEmojiIndex = selectedEmojiIndex
  }
}

public enum EmojiNavigationAction: Equatable {
  case moveUp
  case moveDown
  case moveLeft
  case moveRight
  case resetSelectionWithoutScroll
  case resetSelectionAndScroll
}

public enum EmojiNavigationEffect: Equatable {
  case scrollToSelectedIndex
}

public enum EmojiNavigationReducer {
  @discardableResult
  public static func reduce(
    state: inout EmojiNavigationState,
    action: EmojiNavigationAction,
    totalEmojis: Int,
    columns: Int
  ) -> [EmojiNavigationEffect] {
    guard totalEmojis > 0 else { return [] }

    let maxIndex = totalEmojis - 1
    let step = max(columns, 1)
    let previousIndex = state.selectedEmojiIndex

    switch action {
    case .moveUp:
      state.selectedEmojiIndex = max(0, state.selectedEmojiIndex - step)
    case .moveDown:
      state.selectedEmojiIndex = min(maxIndex, state.selectedEmojiIndex + step)
    case .moveLeft:
      state.selectedEmojiIndex = max(0, state.selectedEmojiIndex - 1)
    case .moveRight:
      state.selectedEmojiIndex = min(maxIndex, state.selectedEmojiIndex + 1)
    case .resetSelectionWithoutScroll:
      state.selectedEmojiIndex = 0
    case .resetSelectionAndScroll:
      state.selectedEmojiIndex = 0
    }

    if action == .resetSelectionWithoutScroll {
      return []
    }

    guard previousIndex != state.selectedEmojiIndex else { return [] }
    return [.scrollToSelectedIndex]
  }
}
