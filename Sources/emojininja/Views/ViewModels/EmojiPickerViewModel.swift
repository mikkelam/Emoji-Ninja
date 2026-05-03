import Combine
import SwiftUI
import ninjalib

@MainActor
class EmojiPickerViewModel: ObservableObject {
  @Published var searchText = ""
  @Published var selectedCategory: CategoryType?
  @Published var selectedEmojiIndex = 0
  @Published var currentSearchResults: [EmojibaseEmoji] = []
  @Published private(set) var currentSections: [EmojiSectionSnapshot] = []
  @Published var searchResultsId = UUID()
  @Published private(set) var shouldAutoScrollSelection = false

  private let emojiManager: EmojiManager
  private let dataSource: EmojiDataSource
  private var dataSnapshot: EmojiDataSnapshot = .empty
  private var navigator = EmojiNavigator()
  private var isManualScrollMode = false
  private var lastKeyboardNavigationAt = Date.distantPast
  private let keyboardScrollGraceInterval: TimeInterval = 0.2

  var isInSearchMode: Bool {
    return searchText.count >= 2
  }

  init(emojiManager: EmojiManager) {
    self.emojiManager = emojiManager
    self.dataSource = EmojiDataSource(repository: DefaultEmojiRepository())
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
    searchResultsId = UUID()
  }

  func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
    let allEmojis = dataSnapshot.flatEmojis
    guard !allEmojis.isEmpty else { return .ignored }

    let columns = EmojiLayout.gridColumns
    let sectionCounts = dataSnapshot.sectionCounts
    let action: EmojiNavigationAction

    switch keyPress.key {
    case .upArrow: action = .moveUp
    case .downArrow: action = .moveDown
    case .leftArrow: action = .moveLeft
    case .rightArrow: action = .moveRight
    default: return .ignored
    }

    lastKeyboardNavigationAt = Date()
    isManualScrollMode = false

    let effects = navigator.move(
      action: action,
      totalEmojis: allEmojis.count,
      columns: columns,
      sectionCounts: sectionCounts
    )

    selectedEmojiIndex = navigator.state.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex) && !isManualScrollMode
    return .handled
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

  func onScrollActivity() {
    let isLikelyProgrammaticScroll =
      Date().timeIntervalSince(lastKeyboardNavigationAt) <= keyboardScrollGraceInterval
    guard !isLikelyProgrammaticScroll else { return }
    isManualScrollMode = true
    shouldAutoScrollSelection = false
  }

  func currentScrollTargetId() -> String? {
    let allEmojis = dataSnapshot.flatEmojis
    guard selectedEmojiIndex >= 0 && selectedEmojiIndex < allEmojis.count else { return nil }
    return "emoji_index_\(selectedEmojiIndex)"
  }

  private func refreshDataSnapshot() {
    dataSnapshot = dataSource.makeSnapshot(searchText: searchText, selectedCategory: selectedCategory)
    currentSections = dataSnapshot.sections
    currentSearchResults = isInSearchMode ? dataSnapshot.flatEmojis : []
  }
}
