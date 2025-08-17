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
      fatalError("ninja_menu asset not found in main bundle")
    }
    image.isTemplate = false
    image.size = NSSize(width: 18, height: 18)
    return image
  }

  var body: some Scene {
    MenuBarExtra {
      MenuBarView(appState: appState, emojiManager: emojiManager, themeManager: themeManager)
        .themedEnvironment(themeManager)
        .onAppear {
          // Check accessibility permissions status on startup
          _ = appState.checkAccessibilityPermissions()
        }
    } label: {
      Image(nsImage: menuBarImage)
    }
    .menuBarExtraStyle(.menu)
  }

  @MainActor
  private func logEmojiDataStats() {
    let dataManager = AppEmojiManager.shared
    _ = dataManager.getAllEmojis()
    _ = dataManager.getAvailableGroups()
  }
}
