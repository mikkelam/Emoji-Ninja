import SwiftUI

// MARK: - Emoji Styling Components
struct EmojiStyling {
    static func buttonSize(for geometry: GeometryProxy, theme: Theme) -> CGFloat {
        let availableWidth = geometry.size.width - (theme.spacing.medium * 2)
        let spacing: CGFloat = 7 * theme.spacing.small
        return max(60, min(120, (availableWidth - spacing) / 8))
    }

    static func emojiFont(size: CGFloat, theme: Theme) -> Font {
        Font.system(size: size * 0.7)
    }
}

// MARK: - Emoji Button Style
struct EmojiButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    let isSelected: Bool
    let isHovered: Bool
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EmojiStyling.emojiFont(size: size, theme: theme))
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                    .stroke(borderColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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

// MARK: - Category Pill Style
struct CategoryPillStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .padding(.horizontal, theme.spacing.small)
            .padding(.vertical, theme.spacing.small)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.pill)
                    .fill(backgroundColor)
            )
            .foregroundColor(textColor)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var backgroundColor: Color {
        isSelected ? theme.colors.accent : theme.colors.surface
    }

    private var textColor: Color {
        isSelected ? theme.colors.text.inverse : theme.colors.text.primary
    }
}

// MARK: - Search Bar Style
struct SearchBarStyle: ViewModifier {
    @Environment(\.theme) private var theme
    let isFocused: Bool

    func body(content: Content) -> some View {
        content
            .font(theme.typography.title)
            .foregroundColor(theme.colors.text.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
    }
}

// MARK: - Skin Tone Selector Style
struct SkinToneSelectorStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.emoji.medium)
            .frame(width: 45, height: 45)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .fill(theme.colors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                            .stroke(theme.colors.border.primary, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            .themedShadow(.small)
    }
}

// MARK: - Empty State Style
struct EmptyStateStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(theme.spacing.xxl)
    }
}

// MARK: - Menu Bar Style
struct MenuBarStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.medium)
            .frame(minWidth: 200)
            .background(theme.colors.background)
    }
}

// MARK: - Icon Style
struct IconStyle: ViewModifier {
    @Environment(\.theme) private var theme
    let color: IconColor
    let size: IconSize

    func body(content: Content) -> some View {
        content
            .font(iconFont)
            .foregroundColor(iconColor)
    }

    private var iconFont: Font {
        switch size {
        case .small:
            return theme.typography.caption
        case .medium:
            return theme.typography.body
        case .large:
            return theme.typography.headline
        case .extraLarge:
            return theme.typography.title
        }
    }

    private var iconColor: Color {
        switch color {
        case .primary:
            return theme.colors.text.primary
        case .secondary:
            return theme.colors.text.secondary
        case .accent:
            return theme.colors.accent
        case .success:
            return theme.colors.semantic.success
        case .warning:
            return theme.colors.semantic.warning
        case .error:
            return theme.colors.semantic.error
        case .info:
            return theme.colors.semantic.info
        }
    }
}

// MARK: - Tooltip Style
struct TooltipStyle: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(theme.colors.text.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(theme.colors.border.secondary.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Supporting Types
enum IconColor {
    case primary
    case secondary
    case accent
    case success
    case warning
    case error
    case info
}

enum IconSize {
    case small
    case medium
    case large
    case extraLarge
}

// MARK: - View Extensions
extension View {
    func emojiButtonStyle(isSelected: Bool = false, isHovered: Bool = false, size: CGFloat)
        -> some View
    {
        buttonStyle(EmojiButtonStyle(isSelected: isSelected, isHovered: isHovered, size: size))
    }

    func categoryPillStyle(isSelected: Bool = false) -> some View {
        buttonStyle(CategoryPillStyle(isSelected: isSelected))
    }

    func searchBarStyle(isFocused: Bool = false) -> some View {
        modifier(SearchBarStyle(isFocused: isFocused))
    }

    func skinToneSelectorStyle() -> some View {
        modifier(SkinToneSelectorStyle())
    }

    func emptyStateStyle() -> some View {
        modifier(EmptyStateStyle())
    }

    func menuBarStyle() -> some View {
        modifier(MenuBarStyle())
    }

    func iconStyle(color: IconColor = .primary, size: IconSize = .medium) -> some View {
        modifier(IconStyle(color: color, size: size))
    }

    func tooltipStyle() -> some View {
        modifier(TooltipStyle())
    }
}

// MARK: - Animation Presets
struct EmojiAnimations {
    static let selection = Animation.easeInOut(duration: 0.2)
    static let hover = Animation.easeInOut(duration: 0.1)
    static let popup = Animation.spring(dampingFraction: 0.8)
    static let fade = Animation.easeInOut(duration: 0.3)
}

// MARK: - Layout Constants
