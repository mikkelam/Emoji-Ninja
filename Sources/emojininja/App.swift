import AppKit
import ServiceManagement
import SwiftUI
import ninjalib

@main
struct EmojiNinjaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var emojiManager = EmojiManager()
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        // Log emoji data stats on startup
        logEmojiDataStats()
    }

    private var menuBarImage: NSImage {
        guard let image = NSImage(named: "ninja_menu") else {
            fatalError("ninja_menu.png not found")
        }
        image.size = NSSize(width: 16, height: 16)

        return image
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState, emojiManager: emojiManager, themeManager: themeManager)
                .themedEnvironment(themeManager)
                .onAppear {
                    // Request accessibility permissions when app appears
                    if !appState.checkAccessibilityPermissions() {
                        appState.requestAccessibilityPermissions()
                    }
                }
        } label: {
            Image(nsImage: menuBarImage)
        }
        .menuBarExtraStyle(.menu)
    }

    @MainActor
    private func logEmojiDataStats() {
        let dataManager = AppEmojiManager.shared
        let _ = dataManager.getAllEmojis()
        let _ = dataManager.getAvailableGroups()
    }
}
