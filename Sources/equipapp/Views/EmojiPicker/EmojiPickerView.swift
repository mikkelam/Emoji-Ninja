import SwiftUI
import equiplib

struct EmojiPickerView: View {
    let windowSize: CGSize
    let onEmojiSelected: (String) -> Void
    @ObservedObject var emojiManager: EmojiManager
    @StateObject private var viewModel: EmojiPickerViewModel
    @Environment(\.theme) private var theme

    init(
        windowSize: CGSize, onEmojiSelected: @escaping (String) -> Void, emojiManager: EmojiManager
    ) {
        self.windowSize = windowSize
        self.onEmojiSelected = onEmojiSelected
        self.emojiManager = emojiManager
        self._viewModel = StateObject(
            wrappedValue: EmojiPickerViewModel(emojiManager: emojiManager))
    }

    var body: some View {
        GeometryReader { geometry in
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
                if viewModel.searchText.isEmpty {
                    CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
                }

                Divider()

                // Emoji Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            if viewModel.searchText.isEmpty {
                                // Category browsing mode
                                EmojiGridView(
                                    geometry: geometry,
                                    selectedEmojiIndex: viewModel.selectedEmojiIndex,
                                    selectedCategory: viewModel.selectedCategory,
                                    onEmojiSelected: onEmojiSelected,
                                    emojiManager: emojiManager
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
        if let selectedEmoji = viewModel.selectCurrentEmoji() {
            onEmojiSelected(selectedEmoji)
        }
    }
}
