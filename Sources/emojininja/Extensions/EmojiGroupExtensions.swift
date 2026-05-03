import Foundation
import ninjalib

// MARK: - App-specific EmojiGroup Extensions

extension EmojiGroup {
  /// Get available groups that have supported emojis
  @MainActor
  static var availableGroups: [EmojiGroup] {
    return allCases.filter { group in
      !AppEmojiManager.shared.getEmojis(for: group).isEmpty
        && group.name.lowercased() != "components"
    }
  }
}
