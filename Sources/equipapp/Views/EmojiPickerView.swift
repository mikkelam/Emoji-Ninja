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

    private var adaptiveColumns: [GridItem] {
        Array(
            repeating: GridItem(.adaptive(minimum: 60, maximum: 120), spacing: theme.spacing.small),
            count: 8)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Category Filter Pills
                if searchText.isEmpty {
                    categoryFilterView
                }

                Divider()

                // Emoji Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if searchText.isEmpty {
                                // Category browsing mode
                                categoryBrowsingView(geometry: geometry)
                            } else {
                                // Search results mode
                                searchResultsView(geometry: geometry)
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
            DispatchQueue.main.async {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 0) {
            // Search field fills entire width
            HStack {
                Image(systemName: "magnifyingglass")
                    .iconStyle(color: .secondary, size: .medium)
                    .padding(.leading, theme.spacing.medium)

                TextField("Search emojis...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .font(theme.typography.title)
                    .onKeyPress { keyPress in
                        // Handle arrow keys for navigation, let other keys through for typing
                        if keyPress.key == .upArrow || keyPress.key == .downArrow
                            || keyPress.key == .leftArrow || keyPress.key == .rightArrow
                        {
                            return handleKeyPress(keyPress)
                        } else if keyPress.key == .return {
                            selectCurrentEmoji()
                            return .handled
                        } else if keyPress.key == .escape {
                            emojiManager.hidePicker()
                            return .handled
                        }
                        return .ignored
                    }
                    .onSubmit {
                        // Select current emoji on Enter
                        selectCurrentEmoji()
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .iconStyle(color: .secondary, size: .medium)
                    }
                    .buttonStyle(.plain)
                }

                // Skin tone selector integrated into search bar
                Menu {
                    ForEach(SkinTone.allCases) { tone in
                        Button(action: {
                            emojiManager.selectedSkinTone = tone
                        }) {
                            HStack {
                                Text(tone.emoji)
                                    .font(.system(size: 20))
                                Text(tone.name)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                    }
                } label: {
                    Text(emojiManager.selectedSkinTone.emoji)
                        .skinToneSelectorStyle()
                }
                .buttonStyle(.plain)
                .padding(.trailing, theme.spacing.medium)
            }
            .searchBarStyle(isFocused: isSearchFocused)
        }
    }

    // MARK: - Category Filter
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.small) {
                // All categories button
                CategoryPill(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                // Individual category buttons
                ForEach(EmojiCategory.availableCategories, id: \.self) { category in
                    CategoryPill(
                        title: category.name,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, theme.spacing.medium)
        }
        .padding(.vertical, theme.spacing.small)
    }

    // MARK: - Category Browsing
    private func categoryBrowsingView(geometry: GeometryProxy) -> some View {
        ForEach(emojiDataWithIndices, id: \.category.rawValue) { categoryData in
            Section {
                LazyVGrid(columns: adaptiveColumns, spacing: theme.spacing.small) {
                    ForEach(categoryData.emojiIndices, id: \.emoji.unicode) { emojiData in
                        EmojiButton(
                            emoji: emojiData.emoji.unicode,
                            isSelected: emojiData.globalIndex == selectedEmojiIndex,
                            geometry: geometry
                        ) {
                            onEmojiSelected(emojiData.emoji.unicode)
                        }
                        .id("emoji_\(emojiData.globalIndex)")
                    }
                }
            } header: {
                HStack {
                    Text(categoryData.category.name)
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.text.primary)
                    Spacer()
                }
                .padding(.bottom, 2)
                .padding(
                    .top,
                    categoryData.category == EmojiCategory.availableCategories.first
                        ? 0 : theme.spacing.medium)
            }
        }
    }

    // MARK: - Search Results
    private func searchResultsView(geometry: GeometryProxy) -> some View {
        Group {
            if currentSearchResults.isEmpty {
                VStack(spacing: theme.spacing.medium) {
                    Image(systemName: "magnifyingglass")
                        .iconStyle(color: .secondary, size: .extraLarge)

                    Text("No emojis found")
                        .font(theme.typography.headline)
                        .foregroundColor(theme.colors.text.secondary)

                    Text("Try searching for something else")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.text.secondary)
                }
                .emptyStateStyle()
            } else {
                LazyVGrid(columns: adaptiveColumns, spacing: theme.spacing.small) {
                    ForEach(Array(currentSearchResults.enumerated()), id: \.element.unicode) {
                        index, emoji in
                        EmojiButton(
                            emoji: emoji.unicode,
                            isSelected: index == selectedEmojiIndex,
                            geometry: geometry
                        ) {
                            onEmojiSelected(emoji.unicode)
                        }
                        .id("emoji_\(index)_\(searchResultsId)")
                    }
                }
                .id("search_grid_\(searchResultsId)")
            }
        }
    }

    // MARK: - Computed Properties
    private var visibleCategories: [EmojiCategory] {
        if let selectedCategory = selectedCategory {
            return [selectedCategory]
        } else {
            return EmojiCategory.availableCategories
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

    private struct EmojiWithIndex {
        let emoji: EmojibaseEmoji
        let globalIndex: Int
    }

    private struct CategoryWithIndices {
        let category: EmojiCategory
        let emojiIndices: [EmojiWithIndex]
    }

    private var emojiDataWithIndices: [CategoryWithIndices] {
        var globalIndex = 0
        return visibleCategories.map { category in
            let emojiIndices = category.emojis.enumerated().map { localIndex, emoji in
                let result = EmojiWithIndex(emoji: emoji, globalIndex: globalIndex + localIndex)
                return result
            }
            globalIndex += category.emojis.count
            return CategoryWithIndices(category: category, emojiIndices: emojiIndices)
        }
    }

    private func getAllEmojis() -> [EmojibaseEmoji] {
        if searchText.isEmpty {
            let categoryEmojis = visibleCategories.flatMap { $0.emojis }

            return categoryEmojis
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

// MARK: - Supporting Views
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .categoryPillStyle(isSelected: isSelected)
    }
}

struct EmojiButton: View {
    let emoji: String
    let action: () -> Void
    let isSelected: Bool
    let geometry: GeometryProxy
    @Environment(\.theme) private var theme

    init(
        emoji: String, isSelected: Bool = false, geometry: GeometryProxy,
        action: @escaping () -> Void
    ) {
        self.emoji = emoji
        self.isSelected = isSelected
        self.geometry = geometry
        self.action = action
    }

    @State private var isHovered = false

    private var buttonSize: CGFloat {
        return EmojiLayout.calculateButtonSize(for: geometry, theme: theme)
    }

    var body: some View {
        Button(action: action) {
            Text(emoji)
        }
        .emojiButtonStyle(isSelected: isSelected, isHovered: isHovered, size: buttonSize)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
