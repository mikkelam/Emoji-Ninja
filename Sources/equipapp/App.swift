import AppKit
import ServiceManagement
import SwiftUI
import equiplib

@main
struct EQuipApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var emojiManager = EmojiManager()

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
            MenuBarView(appState: appState, emojiManager: emojiManager)
        } label: {
            Image(nsImage: menuBarImage)
        }
        .menuBarExtraStyle(.menu)
    }

    private func logEmojiDataStats() {
        let dataManager = AppEmojiManager.shared
        let allEmojis = dataManager.getAllEmojis()
        let availableGroups = dataManager.getAvailableGroups()

        print("\n📊 E-QUIP EMOJI DATA STATISTICS")
        print(String(repeating: "=", count: 40))
        print("📦 Total supported emojis: \(allEmojis.count)")
        print("📁 Available categories: \(availableGroups.count)")
        print("")

        // Log detailed category counts
        for group in availableGroups {
            let groupEmojis = dataManager.getEmojis(for: group)
            print("  \(group.icon) \(group.name): \(groupEmojis.count) emojis")
        }

        print("")
        print("🔍 Sample search results:")

        // Test common searches
        let commonSearches = ["smile", "heart", "fire", "party"]
        for query in commonSearches {
            let results = dataManager.searchEmojis(query: query)
            print("  '\(query)': \(results.count) results")
        }

        print(String(repeating: "=", count: 40))
        print("🎉 E-quip ready with \(allEmojis.count) emojis!")
    }
}
