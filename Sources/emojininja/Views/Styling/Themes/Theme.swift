import SwiftUI

// MARK: - Theme Protocol
protocol Theme {
  var colors: ColorScheme { get }
  var typography: Typography { get }
  var spacing: Spacing { get }
  var cornerRadius: CornerRadius { get }
  var shadows: Shadows { get }
}

// MARK: - Color Scheme
struct ColorScheme {
  let background: Color
  let surface: Color
  let surfaceElevated: Color
  let primary: Color
  let secondary: Color
  let accent: Color
  let text: TextColors
  let border: BorderColors
  let semantic: SemanticColors
}

struct TextColors {
  let primary: Color
  let secondary: Color
  let tertiary: Color
  let inverse: Color
  let disabled: Color
}

struct BorderColors {
  let primary: Color
  let secondary: Color
  let selected: Color
  let hover: Color
  let focus: Color
}

struct SemanticColors {
  let success: Color
  let warning: Color
  let error: Color
  let info: Color
}

// MARK: - Typography
struct Typography {
  let largeTitle: Font
  let title: Font
  let headline: Font
  let subheadline: Font
  let body: Font
  let caption: Font
  let caption2: Font
  let emoji: EmojiTypography
}

struct EmojiTypography {
  let small: Font
  let medium: Font
  let large: Font
  let extraLarge: Font
}

// MARK: - Spacing
struct Spacing {
  let xs: CGFloat  // 4
  let small: CGFloat  // 8
  let medium: CGFloat  // 16
  let large: CGFloat  // 24
  let xl: CGFloat  // 32
  let xxl: CGFloat  // 48
}

// MARK: - Corner Radius
struct CornerRadius {
  let small: CGFloat  // 4
  let medium: CGFloat  // 8
  let large: CGFloat  // 12
  let xl: CGFloat  // 16
  let pill: CGFloat  // 999
}

// MARK: - Shadows
struct Shadows {
  let small: ShadowStyle
  let medium: ShadowStyle
  let large: ShadowStyle
}

struct ShadowStyle {
  let color: Color
  let radius: CGFloat
  let x: CGFloat
  let y: CGFloat
}

// MARK: - Dark Theme Implementation
struct DarkTheme: Theme {
  let colors = ColorScheme(
    background: Color(red: 35 / 255, green: 35 / 255, blue: 35 / 255),
    surface: Color(red: 45 / 255, green: 45 / 255, blue: 45 / 255),
    surfaceElevated: Color(red: 55 / 255, green: 55 / 255, blue: 55 / 255),
    primary: Color.white,
    secondary: Color(red: 180 / 255, green: 180 / 255, blue: 180 / 255),
    accent: Color.accentColor,
    text: TextColors(
      primary: Color.white,
      secondary: Color(red: 180 / 255, green: 180 / 255, blue: 180 / 255),
      tertiary: Color(red: 120 / 255, green: 120 / 255, blue: 120 / 255),
      inverse: Color.black,
      disabled: Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255)
    ),
    border: BorderColors(
      primary: Color(red: 70 / 255, green: 70 / 255, blue: 70 / 255),
      secondary: Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255),
      selected: Color(red: 205 / 255, green: 205 / 255, blue: 205 / 255),
      hover: Color(red: 105 / 255, green: 105 / 255, blue: 105 / 255),
      focus: Color.accentColor
    ),
    semantic: SemanticColors(
      success: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
      warning: Color(red: 255 / 255, green: 204 / 255, blue: 0 / 255),
      error: Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255),
      info: Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)
    )
  )

  let typography = Typography(
    largeTitle: .system(size: 34, weight: .bold),
    title: .system(size: 28, weight: .semibold),
    headline: .system(size: 17, weight: .semibold),
    subheadline: .system(size: 15, weight: .medium),
    body: .system(size: 17, weight: .regular),
    caption: .system(size: 12, weight: .regular),
    caption2: .system(size: 11, weight: .regular),
    emoji: EmojiTypography(
      small: .system(size: 16),
      medium: .system(size: 24),
      large: .system(size: 32),
      extraLarge: .system(size: 48)
    )
  )

  let spacing = Spacing(
    xs: 4,
    small: 8,
    medium: 16,
    large: 24,
    xl: 32,
    xxl: 48
  )

  let cornerRadius = CornerRadius(
    small: 4,
    medium: 8,
    large: 12,
    xl: 16,
    pill: 999
  )

  let shadows = Shadows(
    small: ShadowStyle(
      color: Color.black.opacity(0.1),
      radius: 2,
      x: 0,
      y: 1
    ),
    medium: ShadowStyle(
      color: Color.black.opacity(0.15),
      radius: 4,
      x: 0,
      y: 2
    ),
    large: ShadowStyle(
      color: Color.black.opacity(0.2),
      radius: 8,
      x: 0,
      y: 4
    )
  )
}

// MARK: - Light Theme Implementation
struct LightTheme: Theme {
  let colors = ColorScheme(
    background: Color(red: 232 / 255, green: 232 / 255, blue: 232 / 255),
    surface: Color.white,
    surfaceElevated: Color.white,
    primary: Color.black,
    secondary: Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255),
    accent: Color.accentColor,
    text: TextColors(
      primary: Color.black,
      secondary: Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255),
      tertiary: Color(red: 150 / 255, green: 150 / 255, blue: 150 / 255),
      inverse: Color.white,
      disabled: Color(red: 180 / 255, green: 180 / 255, blue: 180 / 255)
    ),
    border: BorderColors(
      primary: Color(red: 200 / 255, green: 200 / 255, blue: 200 / 255),
      secondary: Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255),
      selected: Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255),
      hover: Color(red: 160 / 255, green: 160 / 255, blue: 160 / 255),
      focus: Color.accentColor
    ),
    semantic: SemanticColors(
      success: Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255),
      warning: Color(red: 255 / 255, green: 149 / 255, blue: 0 / 255),
      error: Color(red: 255 / 255, green: 59 / 255, blue: 48 / 255),
      info: Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255)
    )
  )

  let typography = Typography(
    largeTitle: .system(size: 34, weight: .bold),
    title: .system(size: 28, weight: .semibold),
    headline: .system(size: 17, weight: .semibold),
    subheadline: .system(size: 15, weight: .medium),
    body: .system(size: 17, weight: .regular),
    caption: .system(size: 12, weight: .regular),
    caption2: .system(size: 11, weight: .regular),
    emoji: EmojiTypography(
      small: .system(size: 16),
      medium: .system(size: 24),
      large: .system(size: 32),
      extraLarge: .system(size: 48)
    )
  )

  let spacing = Spacing(
    xs: 4,
    small: 8,
    medium: 16,
    large: 24,
    xl: 32,
    xxl: 48
  )

  let cornerRadius = CornerRadius(
    small: 4,
    medium: 8,
    large: 12,
    xl: 16,
    pill: 999
  )

  let shadows = Shadows(
    small: ShadowStyle(
      color: Color.black.opacity(0.05),
      radius: 2,
      x: 0,
      y: 1
    ),
    medium: ShadowStyle(
      color: Color.black.opacity(0.1),
      radius: 4,
      x: 0,
      y: 2
    ),
    large: ShadowStyle(
      color: Color.black.opacity(0.15),
      radius: 8,
      x: 0,
      y: 4
    )
  )
}
