import Combine
import SwiftUI

// MARK: - Theme Manager
@MainActor
class ThemeManager: ObservableObject {
  @Published var currentTheme: Theme
  @Published var themeType: ThemeType

  private let userDefaults = UserDefaults.standard
  private let themeKey = "selectedTheme"

  init() {
    let savedThemeType =
      ThemeType(rawValue: userDefaults.string(forKey: themeKey) ?? "") ?? .system
    self.themeType = savedThemeType
    self.currentTheme = Self.resolveTheme(for: savedThemeType)

    // Listen for system appearance changes
    NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      DispatchQueue.main.async {
        if self?.themeType == .system {
          self?.updateThemeForSystemAppearance()
        }
      }
    }
  }

  func setTheme(_ themeType: ThemeType) {
    self.themeType = themeType
    self.currentTheme = Self.resolveTheme(for: themeType)
    userDefaults.set(themeType.rawValue, forKey: themeKey)
  }

  private func updateThemeForSystemAppearance() {
    if themeType == .system {
      currentTheme = Self.resolveTheme(for: .system)
    }
  }

  private static func resolveTheme(for themeType: ThemeType) -> Theme {
    switch themeType {
    case .light:
      return LightTheme()
    case .dark:
      return DarkTheme()
    case .system:
      return isSystemDarkMode() ? DarkTheme() : LightTheme()
    }
  }

  private static func isSystemDarkMode() -> Bool {
    // Use UserDefaults as the primary method to detect dark mode
    // This is more reliable than NSApp.effectiveAppearance during app initialization
    return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
  }
}

// MARK: - Theme Type
enum ThemeType: String, CaseIterable {
  case light = "light"
  case dark = "dark"
  case system = "system"

  var displayName: String {
    switch self {
    case .light: return "Light"
    case .dark: return "Dark"
    case .system: return "System"
    }
  }

  var icon: String {
    switch self {
    case .light: return "sun.max"
    case .dark: return "moon"
    case .system: return "circle.lefthalf.filled"
    }
  }
}

// MARK: - Environment Key
private struct ThemeEnvironmentKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any Theme = DarkTheme()
}

extension EnvironmentValues {
  var theme: any Theme {
    get { self[ThemeEnvironmentKey.self] }
    set { self[ThemeEnvironmentKey.self] = newValue }
  }
}

// MARK: - View Extension
extension View {
  func themedEnvironment(_ themeManager: ThemeManager) -> some View {
    environment(\.theme, themeManager.currentTheme)
  }
}

// MARK: - Singleton Access
extension ThemeManager {
  static let shared = ThemeManager()
}
