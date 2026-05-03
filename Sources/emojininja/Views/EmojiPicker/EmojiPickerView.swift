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
    let searchSnapshot = viewModel.searchDisplaySnapshot
    let isInSearchMode = searchSnapshot.query.count >= 2

    GeometryReader { geometry in
      ZStack {
        VStack(spacing: 0) {
          // Search Bar
          SearchBar(
            searchText: Binding(
              get: { viewModel.searchText },
              set: { viewModel.setSearchText($0) }
            ),
            emojiManager: emojiManager,
            onKeyPress: viewModel.handleKeyPress,
            onSubmit: handleSubmit,
            onEscape: { emojiManager.hidePicker() }
          )

          // Category Filter Pills
          if !isInSearchMode {
            CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
          }

          Divider()

          // Emoji Content
          ScrollViewReader { proxy in
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 4) {
                Color.clear
                  .frame(height: 1)
                  .id("emoji_content_top")
                if !isInSearchMode {
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
                    buttonSize: EmojiLayout.cachedButtonSize(
                      for: geometry, theme: theme),
                    searchResults: searchSnapshot.results,
                    selectedEmojiIndex: viewModel.selectedEmojiIndex,
                    searchResultsId: searchSnapshot.id,
                    onEmojiSelected: onEmojiSelected
                  )
                }
              }
              .padding(.horizontal, theme.spacing.medium)
              .padding(.vertical, theme.spacing.xs)
            }
            .onChange(of: viewModel.selectedEmojiIndex) { _, _ in
              guard viewModel.shouldAutoScrollSelection else { return }
              if let targetId = viewModel.currentScrollTargetId() {
                DispatchQueue.main.async {
                  proxy.scrollTo(targetId, anchor: .center)
                }
              }
              viewModel.consumeAutoScrollSelection()
            }
            .onChange(of: viewModel.selectedCategory) { _, _ in
              proxy.scrollTo("emoji_content_top", anchor: .top)
              viewModel.onSelectedCategoryChangedFromUI()
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
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
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
