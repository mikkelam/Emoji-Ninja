import Foundation

enum SkinTone: String, CaseIterable, Identifiable {
    case `default` = "default"
    case light = "light"
    case mediumLight = "mediumLight"
    case medium = "medium"
    case mediumDark = "mediumDark"
    case dark = "dark"

    var id: String { rawValue }

    var emoji: String {
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

    var name: String {
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
