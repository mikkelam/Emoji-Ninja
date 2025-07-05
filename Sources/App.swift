import EmojiKit
import ServiceManagement
import SwiftUI

@main
struct EQuipApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var emojiManager = EmojiManager()

    var body: some Scene {
        MenuBarExtra("E-quip", systemImage: "face.smiling") {
            MenuBarView(appState: appState, emojiManager: emojiManager)
        }
        .menuBarExtraStyle(.menu)
    }
}
