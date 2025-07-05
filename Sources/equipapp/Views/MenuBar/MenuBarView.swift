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
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            // Show Emoji Picker Button
            Button(action: {
                viewModel.showEmojiPicker()
            }) {
                HStack {
                    Text("Show Emoji Picker")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.text.primary)
                    Spacer()
                    Text("⌘⌃Space")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.text.secondary)
                }
            }
            .buttonStyle(.plain)

            Divider()
                .background(theme.colors.border.secondary)

            // Launch at Login Toggle
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { viewModel.launchAtLogin },
                        set: { viewModel.launchAtLogin = $0 }
                    )
                )
                .font(theme.typography.body)
                .foregroundColor(theme.colors.text.primary)

                Text("Start E-quip automatically when you log in")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.text.secondary)
            }
            .alert("Launch at Login Error", isPresented: $viewModel.showingLaunchAtLoginAlert) {
                Button("OK") {
                    viewModel.dismissLaunchAtLoginAlert()
                }
            } message: {
                Text(viewModel.launchAtLoginError ?? "Unknown error")
            }

            Divider()
                .background(theme.colors.border.secondary)

            // Theme Submenu
            Menu {
                Button("Light \(viewModel.isCurrentTheme(.light) ? "✓" : "")") {
                    viewModel.setTheme(.light)
                }

                Button("Dark \(viewModel.isCurrentTheme(.dark) ? "✓" : "")") {
                    viewModel.setTheme(.dark)
                }

                Button("System \(viewModel.isCurrentTheme(.system) ? "✓" : "")") {
                    viewModel.setTheme(.system)
                }
            } label: {
                HStack {
                    Text("Theme")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.text.primary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Divider()
                .background(theme.colors.border.secondary)

            // Quit Button
            Button(action: {
                viewModel.quitApp()
            }) {
                HStack {
                    Text("Quit E-quip")
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors.text.primary)
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: [.command])
        }
        .menuBarStyle()
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
