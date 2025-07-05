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
