import Combine
import SwiftUI
import ninjalib

@MainActor
class EmojiPickerViewModel: ObservableObject {
  @Published var searchText = ""
  @Published var selectedCategory: CategoryType?
  @Published var selectedEmojiIndex = 0
  @Published var currentSearchResults: [EmojibaseEmoji] = []
  @Published var searchResultsId = UUID()
  @Published private(set) var shouldAutoScrollSelection = false

  private let emojiManager: EmojiManager
  private var navigationState = EmojiNavigationState()

  var isInSearchMode: Bool {
    return searchText.count >= 2
  }

  init(emojiManager: EmojiManager) {
    self.emojiManager = emojiManager
    setupObservers()
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
    if !isInSearchMode {
      currentSearchResults = []
    } else {
      currentSearchResults = AppEmojiManager.shared.searchEmojisWithSearchKit(
        query: searchText)
    }
    searchResultsId = UUID()
  }

  func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
    let allEmojis = getAllEmojis()
    guard !allEmojis.isEmpty else { return .ignored }

    let columns = EmojiLayout.gridColumns
    let sectionCounts = getSectionCountsForNavigation()
    let action: EmojiNavigationAction

    switch keyPress.key {
    case .upArrow: action = .moveUp
    case .downArrow: action = .moveDown
    case .leftArrow: action = .moveLeft
    case .rightArrow: action = .moveRight
    default: return .ignored
    }

    let effects = EmojiNavigationReducer.reduce(
      state: &navigationState,
      action: action,
      totalEmojis: allEmojis.count,
      columns: columns,
      sectionCounts: sectionCounts
    )

    selectedEmojiIndex = navigationState.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
    return .handled
  }

  func selectCurrentEmoji() -> String? {
    let allEmojis = getAllEmojis()
    guard selectedEmojiIndex < allEmojis.count else { return nil }
    return allEmojis[selectedEmojiIndex].unicode
  }

  func selectCurrentEmojiData() -> EmojibaseEmoji? {
    let allEmojis = getAllEmojis()
    guard selectedEmojiIndex < allEmojis.count else { return nil }
    return allEmojis[selectedEmojiIndex]
  }

  func getCurrentEmoji() -> EmojibaseEmoji? {
    let allEmojis = getAllEmojis()
    guard selectedEmojiIndex < allEmojis.count else { return nil }
    return allEmojis[selectedEmojiIndex]
  }

  func resetSearch() {
    let effects = EmojiNavigationReducer.reduce(
      state: &navigationState,
      action: .resetSelectionWithoutScroll,
      totalEmojis: max(getAllEmojis().count, 1),
      columns: EmojiLayout.gridColumns
    )
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
    searchText = ""
    selectedEmojiIndex = navigationState.selectedEmojiIndex
    selectedCategory = nil
    updateSearchResults()
  }

  func onSearchTextChanged() {
    let effects = EmojiNavigationReducer.reduce(
      state: &navigationState,
      action: .resetSelectionWithoutScroll,
      totalEmojis: max(getAllEmojis().count, 1),
      columns: EmojiLayout.gridColumns
    )
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
    selectedEmojiIndex = navigationState.selectedEmojiIndex
    updateSearchResults()
  }

  // MARK: - Private Methods

  // MARK: - Category Navigation

  func navigateToNextCategory() {
    // Skip category navigation while in search mode
    guard !isInSearchMode else { return }

    let availableCategories = getAvailableCategories()
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

    let effects = EmojiNavigationReducer.reduce(
      state: &navigationState,
      action: .resetSelectionAndScroll,
      totalEmojis: max(getAllEmojis().count, 1),
      columns: EmojiLayout.gridColumns
    )
    selectedEmojiIndex = navigationState.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
  }

  func navigateToPreviousCategory() {
    // Skip category navigation while in search mode
    guard !isInSearchMode else { return }

    let availableCategories = getAvailableCategories()
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

    let effects = EmojiNavigationReducer.reduce(
      state: &navigationState,
      action: .resetSelectionAndScroll,
      totalEmojis: max(getAllEmojis().count, 1),
      columns: EmojiLayout.gridColumns
    )
    selectedEmojiIndex = navigationState.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
  }

  func onSelectedCategoryChangedFromUI() {
    let effects = EmojiNavigationReducer.reduce(
      state: &navigationState,
      action: .resetSelectionWithoutScroll,
      totalEmojis: max(getAllEmojis().count, 1),
      columns: EmojiLayout.gridColumns
    )
    selectedEmojiIndex = navigationState.selectedEmojiIndex
    shouldAutoScrollSelection = effects.contains(.scrollToSelectedIndex)
  }

  private func getAvailableCategories() -> [CategoryType] {
    var categories: [CategoryType] = []

    // Add frequently used if available
    if FrequentlyUsedEmojiManager.shared.hasFrequentlyUsedEmojis() {
      categories.append(.frequentlyUsed)
    }

    // Add regular categories
    categories.append(contentsOf: EmojiGroup.availableGroups.map { .regular($0) })

    return categories
  }

  private func getAllEmojis() -> [EmojibaseEmoji] {
    if !isInSearchMode {
      if let selectedCategory = selectedCategory {
        return selectedCategory.getEmojis()
      } else {
        // Show all categories
        return CategoryType.availableCategories.flatMap { $0.getEmojis() }
      }
    } else {
      return currentSearchResults
    }
  }

  private func getSectionCountsForNavigation() -> [Int] {
    if isInSearchMode {
      return [currentSearchResults.count]
    }
    if let selectedCategory {
      return [selectedCategory.getEmojis().count]
    }
    return CategoryType.availableCategories.map { $0.getEmojis().count }
  }

  func consumeAutoScrollSelection() {
    shouldAutoScrollSelection = false
  }
}
