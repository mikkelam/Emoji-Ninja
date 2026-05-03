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
    columns: Int,
    sectionCounts: [Int]? = nil
  ) -> [EmojiNavigationEffect] {
    guard totalEmojis > 0 else { return [] }

    let previousIndex = state.selectedEmojiIndex
    state.selectedEmojiIndex = nextIndex(
      currentIndex: state.selectedEmojiIndex,
      action: action,
      totalEmojis: totalEmojis,
      columns: columns,
      sectionCounts: sectionCounts
    )

    if action == .resetSelectionWithoutScroll {
      return []
    }

    guard previousIndex != state.selectedEmojiIndex else { return [] }
    return [.scrollToSelectedIndex]
  }

  private static func nextIndex(
    currentIndex: Int,
    action: EmojiNavigationAction,
    totalEmojis: Int,
    columns: Int,
    sectionCounts: [Int]?
  ) -> Int {
    let maxIndex = totalEmojis - 1
    let step = max(columns, 1)

    switch action {
    case .moveUp:
      if let sectionCounts {
        return moveUpInSections(
          currentIndex: currentIndex,
          sectionCounts: sectionCounts,
          columns: step
        )
      }
      return max(0, currentIndex - step)
    case .moveDown:
      if let sectionCounts {
        return moveDownInSections(
          currentIndex: currentIndex,
          sectionCounts: sectionCounts,
          columns: step
        )
      }
      return min(maxIndex, currentIndex + step)
    case .moveLeft:
      return max(0, currentIndex - 1)
    case .moveRight:
      return min(maxIndex, currentIndex + 1)
    case .resetSelectionWithoutScroll, .resetSelectionAndScroll:
      return 0
    }
  }

  private static func moveDownInSections(
    currentIndex: Int,
    sectionCounts: [Int],
    columns: Int
  ) -> Int {
    guard let position = toSectionPosition(globalIndex: currentIndex, sectionCounts: sectionCounts) else {
      return currentIndex
    }

    let column = position.localIndex % columns
    let row = position.localIndex / columns
    let currentSectionCount = sectionCounts[position.sectionIndex]
    let nextLocalInSameSection = (row + 1) * columns + column
    if nextLocalInSameSection < currentSectionCount {
      return sectionStart(for: position.sectionIndex, sectionCounts: sectionCounts) + nextLocalInSameSection
    }

    for nextSection in (position.sectionIndex + 1)..<sectionCounts.count {
      let count = sectionCounts[nextSection]
      guard count > 0 else { continue }
      let firstRowCount = min(columns, count)
      let nextLocal = min(column, firstRowCount - 1)
      return sectionStart(for: nextSection, sectionCounts: sectionCounts) + nextLocal
    }

    return currentIndex
  }

  private static func moveUpInSections(
    currentIndex: Int,
    sectionCounts: [Int],
    columns: Int
  ) -> Int {
    guard let position = toSectionPosition(globalIndex: currentIndex, sectionCounts: sectionCounts) else {
      return currentIndex
    }

    let column = position.localIndex % columns
    let row = position.localIndex / columns
    if row > 0 {
      let previousLocalInSameSection = (row - 1) * columns + column
      return sectionStart(for: position.sectionIndex, sectionCounts: sectionCounts) + previousLocalInSameSection
    }

    for previousSection in stride(from: position.sectionIndex - 1, through: 0, by: -1) {
      let count = sectionCounts[previousSection]
      guard count > 0 else { continue }
      let start = sectionStart(for: previousSection, sectionCounts: sectionCounts)
      for local in stride(from: count - 1, through: 0, by: -1) where local % columns == column {
        return start + local
      }
      return start + (count - 1)
    }

    return currentIndex
  }

  private static func toSectionPosition(
    globalIndex: Int,
    sectionCounts: [Int]
  ) -> (sectionIndex: Int, localIndex: Int)? {
    var start = 0
    for (sectionIndex, count) in sectionCounts.enumerated() {
      let end = start + count
      if globalIndex >= start && globalIndex < end {
        return (sectionIndex, globalIndex - start)
      }
      start = end
    }
    return nil
  }

  private static func sectionStart(for sectionIndex: Int, sectionCounts: [Int]) -> Int {
    guard sectionIndex > 0 else { return 0 }
    return sectionCounts[..<sectionIndex].reduce(0, +)
  }
}
