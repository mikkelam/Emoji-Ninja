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
            .sink { [weak self] newCategory in
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

        let columns = 8
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
