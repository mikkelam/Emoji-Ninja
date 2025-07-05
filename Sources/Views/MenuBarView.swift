import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var emojiManager: EmojiManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Show Emoji Picker Button
            Button(action: {
                emojiManager.showPicker()
            }) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.primary)
                    Text("Show Emoji Picker")
                    Spacer()
                    Text("⌘⌃Space")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Divider()

            // Launch at Login Toggle
            VStack(alignment: .leading, spacing: 4) {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { appState.launchAtLogin },
                        set: { appState.launchAtLogin = $0 }
                    ))

                Text("Start E-quip automatically when you log in")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .alert("Launch at Login Error", isPresented: $appState.showingLaunchAtLoginAlert) {
                Button("OK") {}
            } message: {
                Text(appState.launchAtLoginError ?? "Unknown error")
            }

            Divider()

            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                    Text("Quit E-quip")
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding()
        .frame(minWidth: 200)
    }
}

#Preview {
    MenuBarView(
        appState: AppState(),
        emojiManager: EmojiManager()
    )
}
