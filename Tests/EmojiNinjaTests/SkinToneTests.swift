import Testing

@testable import ninjalib

struct SkinToneTests {

    @Test func basicFunctionality() {
        #expect(SkinTone.allCases.count == 6)

        // Test default has no modifier
        #expect(SkinTone.default.modifier == nil)

        // Test others have modifiers
        #expect(SkinTone.light.modifier != nil)
        #expect(SkinTone.dark.modifier != nil)
    }

    @Test func emojiComposition() {
        // Test that we can compose emojis with skin tones
        #expect(SkinTone.default.emoji == "👋")
        #expect(SkinTone.light.emoji == "👋🏻")
        #expect(SkinTone.dark.emoji == "👋🏿")

        // Verify modified emojis are different from base
        #expect(SkinTone.light.emoji != SkinTone.default.emoji)
    }

    @Test func namesExist() {
        for skinTone in SkinTone.allCases {
            #expect(!skinTone.name.isEmpty)
        }
    }
}
