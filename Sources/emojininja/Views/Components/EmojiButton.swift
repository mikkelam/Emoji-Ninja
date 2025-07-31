import SwiftUI
import ninjalib

struct FastEmojiButton: View {
    let emojiData: EmojibaseEmoji
    let action: () -> Void
    let isSelected: Bool
    let geometry: GeometryProxy
    @Environment(\.theme) private var theme
    @State private var isHovered = false
    @State private var isPressed = false
    @EnvironmentObject var tooltipManager: TooltipManager

    init(
        emojiData: EmojibaseEmoji,
        isSelected: Bool = false,
        geometry: GeometryProxy,
        action: @escaping () -> Void
    ) {
        self.emojiData = emojiData
        self.isSelected = isSelected
        self.geometry = geometry
        self.action = action
    }

    private var buttonSize: CGFloat {
        return EmojiLayout.calculateButtonSize(for: geometry, theme: theme)
    }

    private var shouldShowEffects: Bool {
        true
    }

    var body: some View {
        GeometryReader { buttonGeometry in
            Text(emojiData.unicode)
                .font(EmojiStyling.emojiFont(size: buttonSize, theme: theme))
                .frame(width: buttonSize, height: buttonSize)
                .background(backgroundView)
                .overlay(overlayView)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .contentShape(Rectangle())
                .onTapGesture(perform: action)
                .onHover { hovering in
                    isHovered = hovering
                    if hovering {
                        NSCursor.pointingHand.push()
                        let buttonFrame = buttonGeometry.frame(in: .named("emojiPicker"))
                        tooltipManager.showTooltip(emojiData.label, at: buttonFrame)
                    } else {
                        NSCursor.pop()
                        tooltipManager.hideTooltip()
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            isPressed = true
                        }
                        .onEnded { _ in
                            isPressed = false
                        }
                )
        }
        .frame(width: buttonSize, height: buttonSize)
    }

    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
            .fill(theme.colors.surface)
    }

    @ViewBuilder
    private var overlayView: some View {
        if isSelected || isHovered {
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(borderColor, lineWidth: 2)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return theme.colors.border.selected
        } else if isHovered {
            return theme.colors.border.hover
        } else {
            return Color.clear
        }
    }

}
