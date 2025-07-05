import SwiftUI
import equiplib

struct EmojiButton: View {
    let emoji: String
    let action: () -> Void
    let isSelected: Bool
    let geometry: GeometryProxy
    @Environment(\.theme) private var theme

    init(
        emoji: String, isSelected: Bool = false, geometry: GeometryProxy,
        action: @escaping () -> Void
    ) {
        self.emoji = emoji
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
            Text(emoji)
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
    }
}
