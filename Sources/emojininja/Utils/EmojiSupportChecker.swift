import AppKit
import Foundation
import ninjalib

struct EmojiSupportChecker {
  nonisolated(unsafe) private static let cache = NSCache<NSString, NSNumber>()

  static func isSupported(_ emoji: String) -> Bool {
    let key = emoji as NSString

    if let cached = cache.object(forKey: key) {
      return cached.boolValue
    }

    let supported = checkEmojiSupport(emoji)
    cache.setObject(NSNumber(value: supported), forKey: key)
    return supported
  }

  private static func checkEmojiSupport(_ emoji: String) -> Bool {
    // Simple visual bounds checking
    let systemFont = NSFont.systemFont(ofSize: 16)
    let attributes: [NSAttributedString.Key: Any] = [.font: systemFont]
    let attributedString = NSAttributedString(string: emoji, attributes: attributes)

    let size = attributedString.size()

    // If emoji is supported, it should have reasonable dimensions
    // Unsupported emojis often render as empty boxes or have zero/minimal dimensions
    return size.width > 5 && size.height > 5
  }
}

// Extension to make EmojibaseEmoji work with our support checker
extension EmojibaseEmoji {
  var isSupported: Bool {
    return EmojiSupportChecker.isSupported(self.unicode)
  }
}
