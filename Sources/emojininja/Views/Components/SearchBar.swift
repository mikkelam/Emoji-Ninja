import SwiftUI
import ninjalib

struct SearchBar: View {
  @Binding var searchText: String
  @FocusState private var isSearchFocused: Bool
  @ObservedObject var emojiManager: EmojiManager
  @Environment(\.theme) private var theme

  let onKeyPress: (KeyPress) -> KeyPress.Result
  let onSubmit: () -> Void
  let onEscape: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      // Search field fills entire width
      HStack {
        Image(systemName: "magnifyingglass")
          .iconStyle(color: .secondary, size: .medium)
          .padding(.leading, theme.spacing.medium)

        ZStack(alignment: .leading) {
          if searchText.isEmpty {
            Text("Search emojis...")
              .foregroundColor(theme.colors.text.tertiary)
              .font(theme.typography.title)
          }

          TextField("", text: $searchText)
            .textFieldStyle(.plain)
            .focused($isSearchFocused)
            .font(theme.typography.title)
            .onKeyPress { keyPress in
              // Handle arrow keys and other navigation
              if keyPress.key == .upArrow || keyPress.key == .downArrow
                || keyPress.key == .leftArrow || keyPress.key == .rightArrow {
                return onKeyPress(keyPress)
              } else if keyPress.key == .return {
                onSubmit()
                return .handled
              } else if keyPress.key == .escape {
                if !searchText.isEmpty {
                  // First escape clears search
                  searchText = ""
                  return .handled
                } else {
                  // Second escape or escape with empty search closes picker
                  onEscape()
                  return .handled
                }
              }
              return .ignored
            }
            .onSubmit {
              onSubmit()
            }
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
          ForEach(SkinTone.allCases, id: \.self) { tone in
            Button(action: {
              emojiManager.selectedSkinTone = tone
            }) {
              HStack {
                Text(tone.emoji)
                  .font(theme.typography.emoji.medium)
                Text(tone.name)
                  .font(theme.typography.body)
                Spacer()
              }
            }
          }
        } label: {
          Text(emojiManager.selectedSkinTone.emoji)
            .font(theme.typography.emoji.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .skinToneSelectorStyle()
        .padding(.trailing, theme.spacing.medium)
      }
      .searchBarStyle(isFocused: isSearchFocused)
    }
    .frame(height: 60)
    .background(theme.colors.background)
    .onAppear {
      DispatchQueue.main.async {
        isSearchFocused = true
      }
    }
  }
}
