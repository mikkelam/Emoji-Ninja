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
}
