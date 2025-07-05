# E-quip Theming System

A comprehensive, type-safe theming system for E-quip that supports light/dark themes and dynamic theme switching.

## Overview

The theming system provides a structured approach to styling with:
- **Protocol-based themes** for consistency and extensibility
- **Environment-based theme injection** for seamless SwiftUI integration
- **Dynamic theme switching** with system appearance support
- **Comprehensive styling components** for common UI patterns
- **Type-safe color and typography definitions**

## Core Components

### 1. Theme Protocol

The `Theme` protocol defines the structure for all themes:

```swift
protocol Theme {
    var colors: ColorScheme { get }
    var typography: Typography { get }
    var spacing: Spacing { get }
    var cornerRadius: CornerRadius { get }
    var shadows: Shadows { get }
}
```

### 2. Built-in Themes

#### DarkTheme
- Primary theme for E-quip
- Dark backgrounds with light text
- Optimized for reduced eye strain

#### LightTheme
- Light backgrounds with dark text
- High contrast for accessibility
- Clean, modern appearance

### 3. Theme Manager

`ThemeManager` handles theme switching and persistence:

```swift
@StateObject private var themeManager = ThemeManager.shared

// Set theme programmatically
themeManager.setTheme(.dark)
themeManager.setTheme(.light)
themeManager.setTheme(.system) // Follows system appearance
```

## Usage

### Basic Theme Integration

1. **Inject theme environment** in your app:
```swift
MenuBarView()
    .themedEnvironment(themeManager)
```

2. **Access theme in views**:
```swift
struct MyView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        Text("Hello")
            .foregroundColor(theme.colors.text.primary)
            .font(theme.typography.body)
    }
}
```

### Pre-built Style Modifiers

#### Card Styling
```swift
VStack {
    // Content
}
.themedCard(.medium) // low, medium, high elevation
```

#### Button Styling
```swift
Button("Action") { }
.themedButton(.primary, size: .medium)
// Styles: .primary, .secondary, .ghost, .destructive
// Sizes: .small, .medium, .large
```

#### Text Field Styling
```swift
TextField("Search", text: $searchText)
    .themedTextField(isFocused: isFocused)
```

### Emoji-Specific Styling

#### Emoji Button
```swift
Button("🎉") { }
.emojiButtonStyle(
    isSelected: isSelected,
    isHovered: isHovered,
    size: buttonSize
)
```

#### Category Pills
```swift
Button("Smileys") { }
.categoryPillStyle(isSelected: selectedCategory == .smileys)
```

#### Search Bar
```swift
TextField("Search emojis...", text: $searchText)
    .searchBarStyle(isFocused: isSearchFocused)
```

### Icon Styling

```swift
Image(systemName: "star")
    .iconStyle(color: .accent, size: .medium)
// Colors: .primary, .secondary, .accent, .success, .warning, .error, .info
// Sizes: .small, .medium, .large, .extraLarge
```

## Theme Structure

### Colors
```swift
theme.colors.background        // Main background
theme.colors.surface          // Card/surface background
theme.colors.surfaceElevated  // Elevated surface
theme.colors.primary          // Primary brand color
theme.colors.accent           // Accent color
theme.colors.text.primary     // Primary text
theme.colors.text.secondary   // Secondary text
theme.colors.border.selected  // Selected state border
theme.colors.semantic.success // Success state color
```

### Typography
```swift
theme.typography.largeTitle   // Large titles
theme.typography.title        // Section titles
theme.typography.headline     // Headings
theme.typography.body         // Body text
theme.typography.caption      // Small text
theme.typography.emoji.large  // Large emojis
```

### Spacing
```swift
theme.spacing.xs     // 4pt
theme.spacing.small  // 8pt
theme.spacing.medium // 16pt
theme.spacing.large  // 24pt
theme.spacing.xl     // 32pt
theme.spacing.xxl    // 48pt
```

### Corner Radius
```swift
theme.cornerRadius.small  // 4pt
theme.cornerRadius.medium // 8pt
theme.cornerRadius.large  // 12pt
theme.cornerRadius.xl     // 16pt
theme.cornerRadius.pill   // 999pt (fully rounded)
```

## Theme Settings UI

### Expandable Settings
```swift
ThemeSettingsView(themeManager: themeManager)
```

### Compact Selector
```swift
CompactThemeSelector(themeManager: themeManager)
```

### Status Indicator
```swift
ThemeStatusIndicator(themeManager: themeManager)
```

## Accessibility

The theming system includes accessibility support:
- **High contrast colors** for better readability
- **Semantic color meanings** for consistent visual communication
- **Scalable typography** that respects system font sizes
- **Proper contrast ratios** between text and backgrounds

## Layout Constants

Common layout values are centralized in `EmojiLayout`:
```swift
EmojiLayout.gridColumns        // Number of emoji columns
EmojiLayout.minButtonSize      // Minimum emoji button size
EmojiLayout.maxButtonSize      // Maximum emoji button size
EmojiLayout.searchBarHeight    // Standard search bar height
```

## Animation Presets

Consistent animations throughout the app:
```swift
EmojiAnimations.selection  // For selection states
EmojiAnimations.hover      // For hover effects
EmojiAnimations.popup      // For popup appearances
EmojiAnimations.fade       // For fade transitions
```

## Extending the System

### Creating Custom Themes

1. **Implement the Theme protocol**:
```swift
struct CustomTheme: Theme {
    let colors = ColorScheme(
        background: Color.purple,
        // ... other colors
    )
    // ... other properties
}
```

2. **Add to ThemeManager**:
```swift
// Add new theme type to ThemeType enum
case custom = "custom"

// Update resolveTheme method
case .custom:
    return CustomTheme()
```

### Adding New Style Modifiers

1. **Create a ViewModifier**:
```swift
struct CustomModifier: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(theme.colors.text.primary)
            // ... styling
    }
}
```

2. **Add View extension**:
```swift
extension View {
    func customStyle() -> some View {
        modifier(CustomModifier())
    }
}
```

## Best Practices

1. **Always use theme colors** instead of hardcoded values
2. **Leverage semantic colors** for consistent meaning
3. **Use typography scales** for consistent text sizing
4. **Apply proper spacing** using theme.spacing values
5. **Test in both light and dark themes**
6. **Consider accessibility** when choosing colors and sizes

## Migration Guide

To migrate existing views to the theming system:

1. **Replace hardcoded colors**:
```swift
// Before
.foregroundColor(.white)

// After
.foregroundColor(theme.colors.text.primary)
```

2. **Replace hardcoded fonts**:
```swift
// Before
.font(.system(size: 16, weight: .medium))

// After
.font(theme.typography.body)
```

3. **Replace hardcoded spacing**:
```swift
// Before
.padding(16)

// After
.padding(theme.spacing.medium)
```

4. **Use style modifiers**:
```swift
// Before
.background(Color.gray)
.cornerRadius(8)

// After
.themedCard(.low)
```
