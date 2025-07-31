import Foundation

public enum SkinTone: String, CaseIterable, Identifiable {
  case `default` = "default"
  case light = "light"
  case mediumLight = "mediumLight"
  case medium = "medium"
  case mediumDark = "mediumDark"
  case dark = "dark"

  public var id: String { rawValue }

  public var modifier: String? {
    switch self {
    case .default:
      return nil
    case .light:
      return "1F3FB"
    case .mediumLight:
      return "1F3FC"
    case .medium:
      return "1F3FD"
    case .mediumDark:
      return "1F3FE"
    case .dark:
      return "1F3FF"
    }
  }

  public var emoji: String {
    switch self {
    case .default:
      return "👋"
    case .light:
      return "👋🏻"
    case .mediumLight:
      return "👋🏼"
    case .medium:
      return "👋🏽"
    case .mediumDark:
      return "👋🏾"
    case .dark:
      return "👋🏿"
    }
  }

  public var name: String {
    switch self {
    case .default:
      return "Default"
    case .light:
      return "Light"
    case .mediumLight:
      return "Medium Light"
    case .medium:
      return "Medium"
    case .mediumDark:
      return "Medium Dark"
    case .dark:
      return "Dark"
    }
  }

}
