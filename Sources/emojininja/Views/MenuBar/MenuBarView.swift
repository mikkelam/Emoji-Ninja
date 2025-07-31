import SwiftUI

struct MenuBarView: View {
  @StateObject private var viewModel: MenuBarViewModel
  @Environment(\.theme) private var theme

  init(
    appState: AppState, emojiManager: EmojiManager,
    themeManager: ThemeManager = ThemeManager.shared
  ) {
    self._viewModel = StateObject(
      wrappedValue: MenuBarViewModel(
        appState: appState,
        emojiManager: emojiManager,
        themeManager: themeManager
      )
    )
  }

  var body: some View {
    Button("Show Emoji Picker") {
      viewModel.showEmojiPicker()
    }
    .keyboardShortcut(.space, modifiers: [.command, .control])
    .onAppear {
      // Check if we should show the first launch dialog
      viewModel.checkAndShowFirstLaunchDialog()
    }

    // Accessibility permission status
    if !viewModel.hasAccessibilityPermission {
      Button(action: {
        viewModel.showAccessibilityDialog()
      }) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
          Text("Grant Ninja Powers")
        }
      }
    }

    #if DEBUG
      // Debug-only: Always show permission modal option with status indicator
      Button(action: {
        viewModel.showAccessibilityDialog()
      }) {
        HStack {
          Image(
            systemName: viewModel.hasAccessibilityPermission
              ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
          )
          .foregroundColor(viewModel.hasAccessibilityPermission ? .green : .orange)
          Text("Permission Modal (\(viewModel.hasAccessibilityPermission ? "✓" : "✗"))")
            .foregroundColor(.secondary)
        }
      }
    #endif

    Button(viewModel.launchAtLogin ? "✓ Launch at Login" : "Launch at Login") {
      viewModel.launchAtLogin.toggle()
    }

    Menu("Theme") {
      Button("Light \(viewModel.isCurrentTheme(.light) ? "✓" : "")") {
        viewModel.setTheme(.light)
      }

      Button("Dark \(viewModel.isCurrentTheme(.dark) ? "✓" : "")") {
        viewModel.setTheme(.dark)
      }

      Button("System \(viewModel.isCurrentTheme(.system) ? "✓" : "")") {
        viewModel.setTheme(.system)
      }
    }

    Divider()

    Button("Quit Emoji Ninja") {
      viewModel.quitApp()
    }
    .keyboardShortcut("q", modifiers: [.command])
  }
}

#Preview {
  MenuBarView(
    appState: AppState(),
    emojiManager: EmojiManager(),
    themeManager: ThemeManager.shared
  )
  .themedEnvironment(ThemeManager.shared)
}
