import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var emojiManager: EmojiManager
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            // Show Emoji Picker Button
            Button(action: {
                emojiManager.showPicker()
            }) {
                HStack {
                    Image(systemName: "face.smiling")
                        .iconStyle(color: .primary, size: .medium)
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
                        get: { appState.launchAtLogin },
                        set: { appState.launchAtLogin = $0 }
                    )
                )
                .font(theme.typography.body)
                .foregroundColor(theme.colors.text.primary)

                Text("Start E-quip automatically when you log in")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.text.secondary)
            }
            .alert("Launch at Login Error", isPresented: $appState.showingLaunchAtLoginAlert) {
                Button("OK") {}
            } message: {
                Text(appState.launchAtLoginError ?? "Unknown error")
            }

            Divider()
                .background(theme.colors.border.secondary)

            // Theme Settings
            ThemeSettingsView(themeManager: ThemeManager.shared)

            Divider()
                .background(theme.colors.border.secondary)

            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .iconStyle(color: .error, size: .medium)
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
        emojiManager: EmojiManager()
    )
    .themedEnvironment(ThemeManager.shared)
}
