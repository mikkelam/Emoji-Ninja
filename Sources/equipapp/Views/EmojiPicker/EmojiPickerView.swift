import SwiftUI
import equiplib

struct EmojiPickerView: View {
    let windowSize: CGSize
    let onEmojiSelected: (String) -> Void
    @ObservedObject var emojiManager: EmojiManager
    @Environment(\.theme) private var theme

    @State private var searchText = ""
    @State private var selectedCategory: EmojiCategory?
    @State private var selectedEmojiIndex: Int = 0
    @FocusState private var isSearchFocused: Bool
    @State private var currentSearchResults: [EmojibaseEmoji] = []
    @State private var searchResultsId = UUID()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(
                    searchText: $searchText,
                    emojiManager: emojiManager,
                    onKeyPress: handleKeyPress,
                    onSubmit: selectCurrentEmoji,
                    onEscape: { emojiManager.hidePicker() }
                )

                // Category Filter Pills
                if searchText.isEmpty {
                    CategoryFilterView(selectedCategory: $selectedCategory)
                }

                Divider()

                // Emoji Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if searchText.isEmpty {
                                // Category browsing mode
                                EmojiGridView(
                                    geometry: geometry,
                                    selectedEmojiIndex: selectedEmojiIndex,
                                    selectedCategory: selectedCategory,
                                    onEmojiSelected: onEmojiSelected,
                                    emojiManager: emojiManager
                                )
                            } else {
                                // Search results mode
                                SearchResultsView(
                                    geometry: geometry,
                                    searchResults: currentSearchResults,
                                    selectedEmojiIndex: selectedEmojiIndex,
                                    searchResultsId: searchResultsId,
                                    onEmojiSelected: onEmojiSelected
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.medium)
                        .padding(.vertical, theme.spacing.xs)
                    }
                    .onChange(of: selectedEmojiIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("emoji_\(newIndex)", anchor: .center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.background)
        }
        .frame(width: windowSize.width, height: windowSize.height)
        .onAppear {
            DispatchQueue.main.async {
                isSearchFocused = true
            }
            selectedEmojiIndex = 0
            searchText = ""
            updateSearchResults()
        }
        .onChange(of: searchText) { _, _ in
            selectedEmojiIndex = 0
            updateSearchResults()
            searchResultsId = UUID()
        }
        .onChange(of: emojiManager.shouldResetSearch) { _, shouldReset in
            if shouldReset {
                searchText = ""
                selectedEmojiIndex = 0
                updateSearchResults()
                emojiManager.shouldResetSearch = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
            _ in
            searchText = ""
            selectedEmojiIndex = 0
            updateSearchResults()
        }
    }

    // MARK: - Helper Functions

    private func updateSearchResults() {
        if searchText.isEmpty {
            currentSearchResults = []
        } else {
            let newResults = AppEmojiManager.shared.searchEmojisWithSearchKit(query: searchText)
            currentSearchResults = newResults
        }
    }

    private func getAllEmojis() -> [EmojibaseEmoji] {
        if searchText.isEmpty {
            let categories =
                selectedCategory != nil ? [selectedCategory!] : EmojiCategory.availableCategories
            return categories.flatMap { $0.emojis }
        } else {
            return currentSearchResults
        }
    }

    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        let allEmojis = getAllEmojis()
        guard !allEmojis.isEmpty else { return .ignored }

        let columns = 8
        let totalEmojis = allEmojis.count

        switch keyPress.key {
        case .upArrow:
            let newIndex = max(0, selectedEmojiIndex - columns)
            selectedEmojiIndex = newIndex
            return .handled

        case .downArrow:
            let newIndex = min(totalEmojis - 1, selectedEmojiIndex + columns)
            selectedEmojiIndex = newIndex
            return .handled

        case .leftArrow:
            let newIndex = max(0, selectedEmojiIndex - 1)
            selectedEmojiIndex = newIndex
            return .handled

        case .rightArrow:
            let newIndex = min(totalEmojis - 1, selectedEmojiIndex + 1)
            selectedEmojiIndex = newIndex
            return .handled

        default:
            return .ignored
        }
    }

    private func selectCurrentEmoji() {
        let allEmojis = getAllEmojis()
        if selectedEmojiIndex < allEmojis.count {
            let selectedEmoji = allEmojis[selectedEmojiIndex]
            onEmojiSelected(selectedEmoji.unicode)
        }
    }
}
