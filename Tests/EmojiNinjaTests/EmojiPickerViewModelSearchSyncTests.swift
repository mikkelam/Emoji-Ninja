import Testing

@testable import emoji

@MainActor
struct EmojiPickerViewModelSearchSyncTests {

  @Test func searchSnapshotStaysSynchronizedWithQuery() async throws {
    let manager = EmojiManager()
    let viewModel = EmojiPickerViewModel(emojiManager: manager)

    viewModel.setSearchText("co")
    await waitForSnapshot(viewModel, query: "co", expectedCount: 60)
    #expect(viewModel.searchDisplaySnapshot.query == "co")
    #expect(viewModel.searchDisplaySnapshot.results.count == 60)
    #expect(viewModel.searchDisplaySnapshot.results.first?.hexcode == "1F1E8-1F1F4")

    viewModel.setSearchText("cow")
    await waitForSnapshot(viewModel, query: "cow", expectedCount: 6)
    #expect(viewModel.searchDisplaySnapshot.query == "cow")
    #expect(viewModel.searchDisplaySnapshot.results.count == 6)
    #expect(viewModel.searchDisplaySnapshot.results.first?.hexcode == "1F42E")

    viewModel.setSearchText("cowb")
    await waitForSnapshot(viewModel, query: "cowb", expectedCount: 1)
    #expect(viewModel.searchDisplaySnapshot.query == "cowb")
    #expect(viewModel.searchDisplaySnapshot.results.count == 1)
    #expect(viewModel.searchDisplaySnapshot.results.first?.hexcode == "1F920")
  }

  @Test func singleCharacterQueryEntersSearchMode() async throws {
    let manager = EmojiManager()
    let viewModel = EmojiPickerViewModel(emojiManager: manager)

    viewModel.setSearchText("1")
    await waitForSnapshot(viewModel, query: "1", expectedCount: 60)
    #expect(viewModel.isInSearchMode)
    let hasThumbsUp = viewModel.searchDisplaySnapshot.results.contains { $0.hexcode == "1F44D" }
    #expect(hasThumbsUp)
  }

  private func waitForSnapshot(
    _ viewModel: EmojiPickerViewModel,
    query: String,
    expectedCount: Int
  ) async {
    for _ in 0..<400 {
      let snapshot = viewModel.searchDisplaySnapshot
      if snapshot.query == query && snapshot.results.count == expectedCount {
        return
      }
      await Task.yield()
    }
  }
}
