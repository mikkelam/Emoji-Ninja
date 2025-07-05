import AppKit
import ServiceManagement
import SwiftUI
import equiplib

@main
struct EQuipApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var emojiManager = EmojiManager()
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        // Log emoji data stats on startup
        logEmojiDataStats()
    }

    private var menuBarImage: NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()

        let emoji = "⚔️"
        let font = NSFont.systemFont(ofSize: 16)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.controlTextColor,
        ]

        let size = emoji.size(withAttributes: attributes)
        let rect = NSRect(
            x: (18 - size.width) / 2,
            y: (18 - size.height) / 2,
            width: size.width,
            height: size.height
        )

        emoji.draw(in: rect, withAttributes: attributes)
        image.unlockFocus()

        image.isTemplate = true
        return image
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState, emojiManager: emojiManager, themeManager: themeManager)
                .themedEnvironment(themeManager)
        } label: {
            Image(nsImage: menuBarImage)
        }
        .menuBarExtraStyle(.menu)
    }

    @MainActor
    private func logEmojiDataStats() {
        let dataManager = AppEmojiManager.shared
        let allEmojis = dataManager.getAllEmojis()
        let availableGroups = dataManager.getAvailableGroups()

        print("\n📊 E-QUIP EMOJI DATA STATISTICS")
        print(String(repeating: "=", count: 40))
        print("📦 Total supported emojis: \(allEmojis.count)")
        print("📁 Available categories: \(availableGroups.count)")
        print("")
    }
}
