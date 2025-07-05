import SwiftUI
import equiplib

struct EmojiButton: View {
    let emojiData: EmojibaseEmoji
    let action: () -> Void
    let isSelected: Bool
    let geometry: GeometryProxy
    @Environment(\.theme) private var theme

    init(
        emojiData: EmojibaseEmoji, isSelected: Bool = false, geometry: GeometryProxy,
        action: @escaping () -> Void
    ) {
        self.emojiData = emojiData
        self.isSelected = isSelected
        self.geometry = geometry
        self.action = action
    }

    @State private var isHovered = false

    private var buttonSize: CGFloat {
        return EmojiLayout.calculateButtonSize(for: geometry, theme: theme)
    }

    var body: some View {
        Button(action: action) {
            Text(emojiData.unicode)
        }
        .emojiButtonStyle(isSelected: isSelected, isHovered: isHovered, size: buttonSize)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .help(emojiData.label)
    }
}
