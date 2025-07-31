import SwiftUI
import ninjalib

struct EmojiPickerView: View {
    let windowSize: CGSize
    let onEmojiSelected: (EmojibaseEmoji) -> Void
    @ObservedObject var emojiManager: EmojiManager
    @StateObject private var viewModel: EmojiPickerViewModel
    @StateObject private var tooltipManager = TooltipManager()
    @Environment(\.theme) private var theme

    init(
        windowSize: CGSize, onEmojiSelected: @escaping (EmojibaseEmoji) -> Void,
        emojiManager: EmojiManager
    ) {
        self.windowSize = windowSize
        self.onEmojiSelected = onEmojiSelected
        self.emojiManager = emojiManager
        self._viewModel = StateObject(
            wrappedValue: EmojiPickerViewModel(emojiManager: emojiManager))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(
                        searchText: $viewModel.searchText,
                        emojiManager: emojiManager,
                        onKeyPress: viewModel.handleKeyPress,
                        onSubmit: handleSubmit,
                        onEscape: { emojiManager.hidePicker() }
                    )

                    // Category Filter Pills
                    if !viewModel.isInSearchMode {
                        CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
                    }

                    Divider()

                    // Emoji Content
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                if !viewModel.isInSearchMode {
                                    // Category browsing mode
                                    EmojiGridView(
                                        geometry: geometry,
                                        selectedEmojiIndex: viewModel.selectedEmojiIndex,
                                        selectedCategory: viewModel.selectedCategory,
                                        onEmojiSelected: onEmojiSelected,
                                        emojiManager: emojiManager,
                                        viewModel: viewModel
                                    )
                                } else {
                                    // Search results mode
                                    SearchResultsView(
                                        geometry: geometry,
                                        searchResults: viewModel.currentSearchResults,
                                        selectedEmojiIndex: viewModel.selectedEmojiIndex,
                                        searchResultsId: viewModel.searchResultsId,
                                        onEmojiSelected: onEmojiSelected
                                    )
                                }
                            }
                            .padding(.horizontal, theme.spacing.medium)
                            .padding(.vertical, theme.spacing.xs)
                        }
                        .onChange(of: viewModel.selectedEmojiIndex) { _, newIndex in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if let currentEmoji = viewModel.getCurrentEmoji() {
                                    proxy.scrollTo(
                                        "emoji_\(currentEmoji.hexcode)",
                                        anchor: .center)
                                }
                            }
                        }
                        .onChange(of: viewModel.selectedCategory) { _, _ in
                            // When category changes, scroll to the selected emoji
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if let currentEmoji = viewModel.getCurrentEmoji() {
                                        proxy.scrollTo(
                                            "emoji_\(currentEmoji.hexcode)",
                                            anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.colors.background)
                .coordinateSpace(name: "emojiPicker")
                .environmentObject(tooltipManager)

                // Global tooltip overlay
                GlobalTooltipView(tooltipManager: tooltipManager)
            }
        }
        .frame(width: windowSize.width, height: windowSize.height)
        .onKeyPress { keyPress in
            // Handle tab navigation using actual characters
            let character = keyPress.key.character

            if character == "\u{19}" || character == "\u{9}" {  // Tab or Shift+Tab
                if !viewModel.isInSearchMode {
                    if character == "\u{19}" {  // Shift+Tab
                        viewModel.navigateToPreviousCategory()
                    } else if character == "\u{9}" {  // Tab
                        viewModel.navigateToNextCategory()
                    }
                }
                // Always handle tab events to prevent focus changes
                return .handled
            }
            return .ignored
        }
        .onAppear {
            viewModel.resetSearch()
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.onSearchTextChanged()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
            _ in
            viewModel.resetSearch()
        }
    }

    // MARK: - Helper Functions

    private func handleSubmit() {
        if let selectedEmojiData = viewModel.selectCurrentEmojiData() {
            onEmojiSelected(selectedEmojiData)
        }
    }
}
