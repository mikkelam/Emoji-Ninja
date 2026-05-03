import Combine
import SwiftUI
import ninjalib

struct SearchDisplaySnapshot {
  let query: String
  let results: [EmojibaseEmoji]
  let id: UUID
}

@MainActor
class EmojiPickerViewModel: ObservableObject {
  @Published var searchText = ""
  @Published var selectedCategory: CategoryType?
  @Published var selectedEmojiIndex = 0
  @Published private(set) var searchDisplaySnapshot = SearchDisplaySnapshot(
    query: "",
    results: [],
    id: UUID()
  )
  @Published private(set) var currentSections: [EmojiSectionSnapshot] = []
  @Published private(set) var shouldAutoScrollSelection = false

  private let emojiManager: EmojiManager
  private let dataSource: EmojiDataSource
  private var dataSnapshot: EmojiDataSnapshot = .empty
  private var navigator = EmojiNavigator()

  var isInSearchMode: Bool {
    return searchText.count >= 2
  }

  convenience init(emojiManager: EmojiManager) {
    self.init(
      emojiManager: emojiManager,
      dataSource: EmojiDataSource(repository: DefaultEmojiRepository())
    )
  }

  init(emojiManager: EmojiManager, dataSource: EmojiDataSource) {
    self.emojiManager = emojiManager
    self.dataSource = dataSource
    setupObservers()
    refreshDataSnapshot()
  }

  private func setupObservers() {
    // Reset search when emoji manager triggers reset
    emojiManager.$shouldResetSearch
      .sink { [weak self] shouldReset in
        if shouldReset {
          self?.resetSearch()
          self?.emojiManager.shouldResetSearch = false
        }
      }
      .store(in: &cancellables)
  }

  private var cancellables = Set<AnyCancellable>()

  // MARK: - Public Methods

  func updateSearchResults() {
    refreshDataSnapshot()
  }

  func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
    switch keyPress.key {
    case .upArrow: return handleNavigationAction(.moveUp) ? .handled : .ignored
    case .downArrow: return handleNavigationAction(.moveDown) ? .handled : .ignored
    case .leftArrow: return handleNavigationAction(.moveLeft) ? .handled : .ignored
    case .rightArrow: return handleNavigationAction(.moveRight) ? .handled : .ignored
    default: return .ignored
    }
  }

  @discardableResult
  func handleNavigationAction(_ action: EmojiNavigationAction) -> Bool {
    let allEmojis = dataSnapshot.flatEmojis
    guard !allEmojis.isEmpty else { return false }

    let columns = EmojiLayout.gridColumns
    let sectionCounts = dataSnapshot.sectionCounts

    let effects = navigator.move(
      action: action,
      totalEmojis: allEmojis.count,
      columns: columns,
      sectionCounts: sectionCounts
    )

    selectedEmojiIndex = navigator.state.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
    return true
  }

  func selectCurrentEmoji() -> String? {
    let allEmojis = dataSnapshot.flatEmojis
    guard selectedEmojiIndex < allEmojis.count else { return nil }
    return allEmojis[selectedEmojiIndex].unicode
  }

  func selectCurrentEmojiData() -> EmojibaseEmoji? {
    let allEmojis = dataSnapshot.flatEmojis
    guard selectedEmojiIndex < allEmojis.count else { return nil }
    return allEmojis[selectedEmojiIndex]
  }

  func getCurrentEmoji() -> EmojibaseEmoji? {
    let allEmojis = dataSnapshot.flatEmojis
    guard selectedEmojiIndex < allEmojis.count else { return nil }
    return allEmojis[selectedEmojiIndex]
  }

  func resetSearch() {
    let effects = navigator.resetWithoutScroll(
      totalEmojis: dataSnapshot.flatEmojis.count,
      columns: EmojiLayout.gridColumns
    )
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
    searchText = ""
    selectedCategory = nil
    refreshDataSnapshot()
    selectedEmojiIndex = navigator.state.selectedEmojiIndex
    updateSearchResults()
  }

  func onSearchTextChanged() {
    let effects = navigator.resetWithoutScroll(
      totalEmojis: dataSnapshot.flatEmojis.count,
      columns: EmojiLayout.gridColumns
    )
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
    updateSearchResults()
    selectedEmojiIndex = navigator.state.selectedEmojiIndex
  }

  func setSearchText(_ newValue: String) {
    guard searchText != newValue else { return }
    searchText = newValue
    onSearchTextChanged()
  }

  // MARK: - Private Methods

  // MARK: - Category Navigation

  func navigateToNextCategory() {
    // Skip category navigation while in search mode
    guard !isInSearchMode else { return }

    let availableCategories = dataSource.makeSnapshot(searchText: "", selectedCategory: nil)
      .sections.map(\.category)
    guard !availableCategories.isEmpty else { return }

    if let currentCategory = selectedCategory {
      if let currentIndex = availableCategories.firstIndex(of: currentCategory) {
        let nextIndex = (currentIndex + 1) % availableCategories.count
        selectedCategory = availableCategories[nextIndex]
      }
    } else {
      // Currently showing "All", move to first category
      selectedCategory = availableCategories.first
    }

    refreshDataSnapshot()
    let effects = navigator.resetAndScroll(
      totalEmojis: dataSnapshot.flatEmojis.count,
      columns: EmojiLayout.gridColumns
    )
    selectedEmojiIndex = navigator.state.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
  }

  func navigateToPreviousCategory() {
    // Skip category navigation while in search mode
    guard !isInSearchMode else { return }

    let availableCategories = dataSource.makeSnapshot(searchText: "", selectedCategory: nil)
      .sections.map(\.category)
    guard !availableCategories.isEmpty else { return }

    if let currentCategory = selectedCategory {
      if let currentIndex = availableCategories.firstIndex(of: currentCategory) {
        let previousIndex =
          currentIndex == 0 ? availableCategories.count - 1 : currentIndex - 1
        selectedCategory = availableCategories[previousIndex]
      }
    } else {
      // Currently showing "All", move to last category
      selectedCategory = availableCategories.last
    }

    refreshDataSnapshot()
    let effects = navigator.resetAndScroll(
      totalEmojis: dataSnapshot.flatEmojis.count,
      columns: EmojiLayout.gridColumns
    )
    selectedEmojiIndex = navigator.state.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
  }

  func onSelectedCategoryChangedFromUI() {
    refreshDataSnapshot()
    let effects = navigator.resetWithoutScroll(
      totalEmojis: dataSnapshot.flatEmojis.count,
      columns: EmojiLayout.gridColumns
    )
    selectedEmojiIndex = navigator.state.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
  }

  func consumeAutoScrollSelection() {
    shouldAutoScrollSelection = false
  }

  func currentScrollTargetId() -> String? {
    let allEmojis = dataSnapshot.flatEmojis
    guard selectedEmojiIndex >= 0 && selectedEmojiIndex < allEmojis.count else { return nil }
    if isInSearchMode {
      return "emoji_index_\(selectedEmojiIndex)_\(allEmojis[selectedEmojiIndex].hexcode)"
    }
    return "emoji_index_\(selectedEmojiIndex)"
  }

  private func refreshDataSnapshot() {
    dataSnapshot = dataSource.makeSnapshot(searchText: searchText, selectedCategory: selectedCategory)
    currentSections = dataSnapshot.sections
    if isInSearchMode {
      searchDisplaySnapshot = SearchDisplaySnapshot(
        query: searchText,
        results: dataSnapshot.flatEmojis,
        id: UUID()
      )
    } else {
      searchDisplaySnapshot = SearchDisplaySnapshot(
        query: "",
        results: [],
        id: UUID()
      )
    }
  }
}
