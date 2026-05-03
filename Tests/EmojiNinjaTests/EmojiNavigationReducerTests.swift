import Testing

@testable import ninjalib

struct EmojiNavigationReducerTests {

  @Test func moveDownEmitsScrollIntentAndUpdatesIndex() {
    var state = EmojiNavigationState(selectedEmojiIndex: 0)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveDown,
      totalEmojis: 20,
      columns: 5
    )

    #expect(state.selectedEmojiIndex == 5)
    #expect(effects == [.scrollToSelectedIndex])
  }

  @Test func moveUpAtTopDoesNotEmitIntent() {
    var state = EmojiNavigationState(selectedEmojiIndex: 0)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveUp,
      totalEmojis: 20,
      columns: 5
    )

    #expect(state.selectedEmojiIndex == 0)
    #expect(effects.isEmpty)
  }

  @Test func moveRightClampsAtEnd() {
    var state = EmojiNavigationState(selectedEmojiIndex: 9)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveRight,
      totalEmojis: 10,
      columns: 5
    )

    #expect(state.selectedEmojiIndex == 9)
    #expect(effects.isEmpty)
  }

  @Test func resetSelectionAndScrollEmitsIntentWhenStateChanges() {
    var state = EmojiNavigationState(selectedEmojiIndex: 4)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .resetSelectionAndScroll,
      totalEmojis: 10,
      columns: 4
    )

    #expect(state.selectedEmojiIndex == 0)
    #expect(effects == [.scrollToSelectedIndex])
  }

  @Test func resetSelectionWithoutScrollDoesNotEmitIntent() {
    var state = EmojiNavigationState(selectedEmojiIndex: 4)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .resetSelectionWithoutScroll,
      totalEmojis: 10,
      columns: 4
    )

    #expect(state.selectedEmojiIndex == 0)
    #expect(effects.isEmpty)
  }

  @Test func moveDownAcrossSectionKeepsColumnWhenAvailable() {
    var state = EmojiNavigationState(selectedEmojiIndex: 2)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveDown,
      totalEmojis: 14,
      columns: 6,
      sectionCounts: [8, 6]
    )

    #expect(state.selectedEmojiIndex == 10)
    #expect(effects == [.scrollToSelectedIndex])
  }

  @Test func moveDownAcrossSectionClampsWhenColumnMissing() {
    var state = EmojiNavigationState(selectedEmojiIndex: 5)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveDown,
      totalEmojis: 11,
      columns: 6,
      sectionCounts: [8, 3]
    )

    #expect(state.selectedEmojiIndex == 10)
    #expect(effects == [.scrollToSelectedIndex])
  }

  @Test func moveUpAcrossSectionKeepsColumnWhenAvailable() {
    var state = EmojiNavigationState(selectedEmojiIndex: 10)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveUp,
      totalEmojis: 14,
      columns: 6,
      sectionCounts: [8, 6]
    )

    #expect(state.selectedEmojiIndex == 2)
    #expect(effects == [.scrollToSelectedIndex])
  }

  @Test func repeatedMoveDownEmitsScrollWhileSelectionAdvances() {
    var state = EmojiNavigationState(selectedEmojiIndex: 0)

    let first = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveDown,
      totalEmojis: 18,
      columns: 6,
      sectionCounts: [18]
    )
    let second = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveDown,
      totalEmojis: 18,
      columns: 6,
      sectionCounts: [18]
    )

    #expect(first == [.scrollToSelectedIndex])
    #expect(second == [.scrollToSelectedIndex])
    #expect(state.selectedEmojiIndex == 12)
  }

  @Test func moveDownAtEndDoesNotEmitScrollIntent() {
    var state = EmojiNavigationState(selectedEmojiIndex: 17)

    let effects = EmojiNavigationReducer.reduce(
      state: &state,
      action: .moveDown,
      totalEmojis: 18,
      columns: 6,
      sectionCounts: [18]
    )

    #expect(state.selectedEmojiIndex == 17)
    #expect(effects.isEmpty)
  }
}
