import SwiftUI

// MARK: - Theme Settings View
struct ThemeSettingsView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.theme) private var theme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            // Theme Section Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "paintbrush")
                        .iconStyle(color: .primary, size: .medium)

                    Text("Theme")
                        .font(theme.typography.subheadline)
                        .foregroundColor(theme.colors.text.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .iconStyle(color: .secondary, size: .small)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            // Theme Options
            if isExpanded {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(ThemeType.allCases, id: \.self) { themeType in
                        ThemeOptionRow(
                            themeType: themeType,
                            isSelected: themeManager.themeType == themeType,
                            onSelect: {
                                themeManager.setTheme(themeType)
                            }
                        )
                    }
                }
                .padding(.leading, theme.spacing.medium)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    @Environment(\.theme) private var theme
    let themeType: ThemeType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: theme.spacing.small) {
                // Theme icon
                Image(systemName: themeType.icon)
                    .iconStyle(color: isSelected ? .accent : .secondary, size: .small)
                    .frame(width: 16, height: 16)

                // Theme name
                Text(themeType.displayName)
                    .font(theme.typography.body)
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.text.primary)

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .iconStyle(color: .accent, size: .small)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, theme.spacing.small)
            .padding(.vertical, theme.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                    .fill(isSelected ? theme.colors.accent.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                    .stroke(
                        isSelected ? theme.colors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Theme Preview
struct ThemePreview: View {
    @Environment(\.theme) private var theme
    let themeType: ThemeType

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            // Color swatches
            Circle()
                .fill(previewTheme.colors.background)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(theme.colors.border.secondary, lineWidth: 0.5)
                )

            Circle()
                .fill(previewTheme.colors.surface)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(theme.colors.border.secondary, lineWidth: 0.5)
                )

            Circle()
                .fill(previewTheme.colors.accent)
                .frame(width: 12, height: 12)
        }
    }

    private var previewTheme: Theme {
        switch themeType {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        case .system:
            return isSystemDarkMode() ? DarkTheme() : LightTheme()
        }
    }

    private func isSystemDarkMode() -> Bool {
        // Use UserDefaults as the primary method to detect dark mode
        // This is more reliable than NSApp.effectiveAppearance during app initialization
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }
}

// MARK: - Compact Theme Selector
struct CompactThemeSelector: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.small) {
            Text("Theme")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.text.secondary)

            Spacer()

            Menu {
                ForEach(ThemeType.allCases, id: \.self) { themeType in
                    Button(action: {
                        themeManager.setTheme(themeType)
                    }) {
                        HStack {
                            Image(systemName: themeType.icon)
                            Text(themeType.displayName)

                            if themeManager.themeType == themeType {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: themeManager.themeType.icon)
                        .iconStyle(color: .accent, size: .small)

                    Text(themeManager.themeType.displayName)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.text.primary)

                    Image(systemName: "chevron.up.chevron.down")
                        .iconStyle(color: .secondary, size: .small)
                }
                .padding(.horizontal, theme.spacing.small)
                .padding(.vertical, theme.spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                        .fill(theme.colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                                .stroke(theme.colors.border.secondary, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Theme Status Indicator
struct ThemeStatusIndicator: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: themeManager.themeType.icon)
                .iconStyle(color: .accent, size: .small)

            Text(statusText)
                .font(theme.typography.caption2)
                .foregroundColor(theme.colors.text.secondary)
        }
        .padding(.horizontal, theme.spacing.small)
        .padding(.vertical, theme.spacing.xs)
        .background(
            Capsule()
                .fill(theme.colors.surface)
                .overlay(
                    Capsule()
                        .stroke(theme.colors.border.secondary, lineWidth: 1)
                )
        )
    }

    private var statusText: String {
        switch themeManager.themeType {
        case .system:
            let isDark = isSystemDarkMode()
            return "Auto (\(isDark ? "Dark" : "Light"))"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    private func isSystemDarkMode() -> Bool {
        // Use UserDefaults as the primary method to detect dark mode
        // This is more reliable than NSApp.effectiveAppearance during app initialization
        return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        ThemeSettingsView(themeManager: ThemeManager.shared)

        Divider()

        CompactThemeSelector(themeManager: ThemeManager.shared)

        Divider()

        ThemeStatusIndicator(themeManager: ThemeManager.shared)
    }
    .themedEnvironment(ThemeManager.shared)
    .menuBarStyle()
}
