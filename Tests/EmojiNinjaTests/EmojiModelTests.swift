import Foundation
import Testing

@testable import ninjalib

struct EmojiModelTests {

  @Test func basicEmojiProperties() throws {
    let dataManager = EmojiDataManager.shared
    let allEmojis = dataManager.getAllEmojis()

    let emoji = try #require(allEmojis.first)

    #expect(!emoji.hexcode.isEmpty)
    #expect(!emoji.label.isEmpty)
    #expect(!emoji.unicode.isEmpty)
    #expect(emoji.isUseful)
  }

  @Test func emojiWithSkinTones() {
    let dataManager = EmojiDataManager.shared
    let allEmojis = dataManager.getAllEmojis()

    // Find an emoji that supports skin tones
    let skinToneEmoji = allEmojis.first { $0.supportsSkinTones }

    if let emoji = skinToneEmoji {
      #expect(emoji.supportsSkinTones)
      #expect(emoji.skins != nil)
      #expect(!(emoji.skins?.isEmpty ?? true))
    }
  }

  @Test func emojiFiltering() {
    let dataManager = EmojiDataManager.shared
    let allEmojis = dataManager.getAllEmojis()

    // Test that filtered emojis don't contain unwanted items
    let hasRegionalIndicators = allEmojis.contains { $0.label.contains("regional indicator") }
    #expect(!hasRegionalIndicators)

    let hasSkinToneModifiers = allEmojis.contains {
      $0.label.lowercased().contains("skin tone")
    }
    #expect(!hasSkinToneModifiers)
  }

  @Test func emojiGroupAssignment() {
    let dataManager = EmojiDataManager.shared
    let allEmojis = dataManager.getAllEmojis()

    // Test that emojis have valid group assignments
    for emoji in allEmojis.prefix(10) {
      if let group = emoji.group {
        #expect(group >= 0)
        #expect(group < 20)  // Reasonable upper bound
      }
    }
  }

  @Test func emojiTags() {
    let dataManager = EmojiDataManager.shared
    let allEmojis = dataManager.getAllEmojis()

    // Find an emoji with tags
    let taggedEmoji = allEmojis.first { $0.tags?.isEmpty == false }

    if let emoji = taggedEmoji {
      #expect(emoji.tags != nil)
      #expect(!emoji.tags!.isEmpty)

      // Test that tags are non-empty strings
      for tag in emoji.tags! {
        #expect(!tag.isEmpty)
      }
    }
  }
}
