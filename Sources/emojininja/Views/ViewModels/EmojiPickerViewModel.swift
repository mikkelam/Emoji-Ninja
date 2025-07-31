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

  private let emojiManager: EmojiManager

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

    // Reset selected emoji index when category changes
    $selectedCategory
      .sink { [weak self] _ in
        self?.selectedEmojiIndex = 0
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
    let totalEmojis = allEmojis.count

    switch keyPress.key {
    case .upArrow:
      selectedEmojiIndex = max(0, selectedEmojiIndex - columns)
      return .handled

    case .downArrow:
      selectedEmojiIndex = min(totalEmojis - 1, selectedEmojiIndex + columns)
      return .handled

    case .leftArrow:
      selectedEmojiIndex = max(0, selectedEmojiIndex - 1)
      return .handled

    case .rightArrow:
      selectedEmojiIndex = min(totalEmojis - 1, selectedEmojiIndex + 1)
      return .handled

    default:
      return .ignored
    }
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
    searchText = ""
    selectedEmojiIndex = 0
    selectedCategory = nil
    updateSearchResults()
  }

  func onSearchTextChanged() {
    selectedEmojiIndex = 0
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

    selectedEmojiIndex = 0
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

    selectedEmojiIndex = 0
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
}
