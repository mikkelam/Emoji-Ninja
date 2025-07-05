import SwiftUI

struct EmojiPickerView: View {
    let windowSize: CGSize
    let onEmojiSelected: (String) -> Void
    @ObservedObject var emojiManager: EmojiManager

    @State private var searchText = ""
    @State private var selectedCategory: EmojiCategory?
    @State private var selectedEmojiIndex: Int = 0
    @FocusState private var isSearchFocused: Bool

    private var adaptiveColumns: [GridItem] {
        Array(repeating: GridItem(.adaptive(minimum: 60, maximum: 120), spacing: 8), count: 8)
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
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                    .onChange(of: selectedEmojiIndex) { _, newIndex in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("emoji_\(newIndex)", anchor: .center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255))
        }
        .frame(width: windowSize.width, height: windowSize.height)
        .onAppear {
            DispatchQueue.main.async {
                isSearchFocused = true
            }
            selectedEmojiIndex = 0
            searchText = ""
        }
        .onChange(of: searchText) { _, _ in
            selectedEmojiIndex = 0
        }
        .onChange(of: emojiManager.shouldResetSearch) { _, shouldReset in
            if shouldReset {
                searchText = ""
                selectedEmojiIndex = 0
                emojiManager.shouldResetSearch = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
            _ in
            searchText = ""
            selectedEmojiIndex = 0
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
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)

                TextField("Search emojis...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .font(.system(size: 24))
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
                            .foregroundColor(.secondary)
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
                                    .font(.system(size: 18))
                                Text(tone.name)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                    }
                } label: {
                    Text(emojiManager.selectedSkinTone.emoji)
                        .font(.system(size: 20))
                        .frame(width: 45, height: 45)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.secondary.opacity(0.1))
        }
        // .padding(.horizontal, 4)
        // .padding(.vertical, 2)
    }

    // MARK: - Category Filter
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
            .padding(.horizontal)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Category Browsing
    private func categoryBrowsingView(geometry: GeometryProxy) -> some View {
        ForEach(emojiDataWithIndices, id: \.category.rawValue) { categoryData in
            Section {
                LazyVGrid(columns: adaptiveColumns, spacing: 8) {
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
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.bottom, 2)
                .padding(
                    .top,
                    categoryData.category == EmojiCategory.availableCategories.first ? 0 : 12)
            }
        }
    }

    // MARK: - Search Results
    private func searchResultsView(geometry: GeometryProxy) -> some View {
        Group {
            if searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No emojis found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Try searching for something else")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: adaptiveColumns, spacing: 8) {
                    ForEach(Array(searchResults.enumerated()), id: \.element.unicode) {
                        index, emoji in
                        EmojiButton(
                            emoji: emoji.unicode,
                            isSelected: index == selectedEmojiIndex,
                            geometry: geometry
                        ) {
                            onEmojiSelected(emoji.unicode)
                        }
                        .id("emoji_\(index)")
                    }
                }
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

    private var searchResults: [EmojibaseEmoji] {
        guard !searchText.isEmpty else { return [] }
        return EmojiCategory.searchEmojis(query: searchText)
    }

    // MARK: - Helper Functions

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
            return visibleCategories.flatMap { $0.emojis }
        } else {
            return searchResults
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
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct EmojiButton: View {
    let emoji: String
    let action: () -> Void
    let isSelected: Bool
    let geometry: GeometryProxy

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
        let availableWidth = geometry.size.width - 32  // Account for padding
        let spacing: CGFloat = 7 * 8  // 7 gaps between 8 columns
        return max(80, min(140, (availableWidth - spacing) / 8))
    }

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: buttonSize * 0.7))
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 45 / 255, green: 45 / 255, blue: 45 / 255))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color(red: 205 / 255, green: 205 / 255, blue: 205 / 255)
        } else if isHovered {
            return Color(red: 105 / 255, green: 105 / 255, blue: 105 / 255)
        } else {
            return Color.clear
        }
    }

    private var backgroundColor: Color {
        return Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255)
    }
}

// MARK: - Preview
#Preview {
    EmojiPickerView(
        windowSize: CGSize(width: 600, height: 400),
        onEmojiSelected: { emoji in
            print("Selected emoji: \(emoji)")
        },
        emojiManager: EmojiManager())
}
