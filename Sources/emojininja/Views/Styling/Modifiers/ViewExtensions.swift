import SwiftUI

// MARK: - View Modifiers
struct ThemedCardModifier: ViewModifier {
  @Environment(\.theme) private var theme
  let elevation: CardElevation

  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
          .fill(surfaceColor)
          .shadow(
            color: shadowStyle.color,
            radius: shadowStyle.radius,
            x: shadowStyle.x,
            y: shadowStyle.y
          )
      )
  }

  private var surfaceColor: Color {
    switch elevation {
    case .low:
      return theme.colors.surface
    case .medium:
      return theme.colors.surfaceElevated
    case .high:
      return theme.colors.surfaceElevated
    }
  }

  private var shadowStyle: ShadowStyle {
    switch elevation {
    case .low:
      return theme.shadows.small
    case .medium:
      return theme.shadows.medium
    case .high:
      return theme.shadows.large
    }
  }
}

struct ThemedButtonModifier: ViewModifier {
  @Environment(\.theme) private var theme
  let style: ButtonThemeStyle
  let size: ButtonSize

  func body(content: Content) -> some View {
    content
      .font(buttonFont)
      .foregroundColor(textColor)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .background(
        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
          .fill(backgroundColor)
          .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
              .stroke(borderColor, lineWidth: 1)
          )
      )
  }

  private var buttonFont: Font {
    switch size {
    case .small:
      return theme.typography.caption
    case .medium:
      return theme.typography.body
    case .large:
      return theme.typography.headline
    }
  }

  private var horizontalPadding: CGFloat {
    switch size {
    case .small:
      return theme.spacing.small
    case .medium:
      return theme.spacing.medium
    case .large:
      return theme.spacing.large
    }
  }

  private var verticalPadding: CGFloat {
    switch size {
    case .small:
      return theme.spacing.xs
    case .medium:
      return theme.spacing.small
    case .large:
      return theme.spacing.medium
    }
  }

  private var backgroundColor: Color {
    switch style {
    case .primary:
      return theme.colors.accent
    case .secondary:
      return theme.colors.surface
    case .ghost:
      return Color.clear
    case .destructive:
      return theme.colors.semantic.error
    }
  }

  private var textColor: Color {
    switch style {
    case .primary:
      return theme.colors.text.inverse
    case .secondary:
      return theme.colors.text.primary
    case .ghost:
      return theme.colors.text.secondary
    case .destructive:
      return theme.colors.text.inverse
    }
  }

  private var borderColor: Color {
    switch style {
    case .primary:
      return Color.clear
    case .secondary:
      return theme.colors.border.primary
    case .ghost:
      return Color.clear
    case .destructive:
      return Color.clear
    }
  }
}

struct ThemedTextFieldModifier: ViewModifier {
  @Environment(\.theme) private var theme
  let isFocused: Bool

  func body(content: Content) -> some View {
    content
      .font(theme.typography.body)
      .foregroundColor(theme.colors.text.primary)
      .padding(.horizontal, theme.spacing.medium)
      .padding(.vertical, theme.spacing.small)
      .background(
        RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
          .fill(theme.colors.surface)
          .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
              .stroke(borderColor, lineWidth: 1)
          )
      )
  }

  private var borderColor: Color {
    isFocused ? theme.colors.border.focus : theme.colors.border.secondary
  }
}

// MARK: - Supporting Types
enum CardElevation {
  case low
  case medium
  case high
}

enum ButtonThemeStyle {
  case primary
  case secondary
  case ghost
  case destructive
}

enum ButtonSize {
  case small
  case medium
  case large
}

// MARK: - View Extensions
extension View {
  func themedCard(_ elevation: CardElevation = .low) -> some View {
    modifier(ThemedCardModifier(elevation: elevation))
  }

  func themedButton(_ style: ButtonThemeStyle = .primary, size: ButtonSize = .medium) -> some View {
    modifier(ThemedButtonModifier(style: style, size: size))
  }

  func themedTextField(isFocused: Bool = false) -> some View {
    modifier(ThemedTextFieldModifier(isFocused: isFocused))
  }

  func themedSpacing(_ spacing: ThemedSpacing = .medium) -> some View {
    modifier(ThemedSpacingModifier(spacing: spacing))
  }

  func themedShadow(_ level: ShadowLevel = .medium) -> some View {
    modifier(ThemedShadowModifier(level: level))
  }
}

// MARK: - Additional Modifiers
struct ThemedSpacingModifier: ViewModifier {
  @Environment(\.theme) private var theme
  let spacing: ThemedSpacing

  func body(content: Content) -> some View {
    content
      .padding(paddingValue)
  }

  private var paddingValue: CGFloat {
    switch spacing {
    case .xs:
      return theme.spacing.xs
    case .small:
      return theme.spacing.small
    case .medium:
      return theme.spacing.medium
    case .large:
      return theme.spacing.large
    case .xl:
      return theme.spacing.xl
    case .xxl:
      return theme.spacing.xxl
    }
  }
}

struct ThemedShadowModifier: ViewModifier {
  @Environment(\.theme) private var theme
  let level: ShadowLevel

  func body(content: Content) -> some View {
    content
      .shadow(
        color: shadowStyle.color,
        radius: shadowStyle.radius,
        x: shadowStyle.x,
        y: shadowStyle.y
      )
  }

  private var shadowStyle: ShadowStyle {
    switch level {
    case .small:
      return theme.shadows.small
    case .medium:
      return theme.shadows.medium
    case .large:
      return theme.shadows.large
    }
  }
}

enum ThemedSpacing {
  case xs
  case small
  case medium
  case large
  case xl
  case xxl
}

enum ShadowLevel {
  case small
  case medium
  case large
}

// MARK: - Color Extensions
extension Color {
  func themed(_ theme: Theme) -> Color {
    self
  }
}

// MARK: - Typography Extensions
extension Text {
  func themedStyle(_ style: TextStyle, theme: Theme) -> some View {
    switch style {
    case .largeTitle:
      return self.font(theme.typography.largeTitle)
        .foregroundColor(theme.colors.text.primary)
    case .title:
      return self.font(theme.typography.title)
        .foregroundColor(theme.colors.text.primary)
    case .headline:
      return self.font(theme.typography.headline)
        .foregroundColor(theme.colors.text.primary)
    case .subheadline:
      return self.font(theme.typography.subheadline)
        .foregroundColor(theme.colors.text.secondary)
    case .body:
      return self.font(theme.typography.body)
        .foregroundColor(theme.colors.text.primary)
    case .caption:
      return self.font(theme.typography.caption)
        .foregroundColor(theme.colors.text.secondary)
    case .caption2:
      return self.font(theme.typography.caption2)
        .foregroundColor(theme.colors.text.tertiary)
    }
  }
}

enum TextStyle {
  case largeTitle
  case title
  case headline
  case subheadline
  case body
  case caption
  case caption2
}
