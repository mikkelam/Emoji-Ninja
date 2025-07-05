import Foundation

public enum SkinTone: String, CaseIterable, Identifiable {
    case `default` = "default"
    case light = "light"
    case mediumLight = "mediumLight"
    case medium = "medium"
    case mediumDark = "mediumDark"
    case dark = "dark"

    public var id: String { rawValue }

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
