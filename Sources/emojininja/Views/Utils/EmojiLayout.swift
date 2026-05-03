import SwiftUI
import ninjalib

/// Utility for emoji layout calculations and caching
struct EmojiLayout {
  // MARK: - Layout Constants

  static let gridColumns = 8
  static let minButtonSize: CGFloat = 58
  static let maxButtonSize: CGFloat = 118
  static let searchBarHeight: CGFloat = 60
  static let categoryPillHeight: CGFloat = 32
  static let skinToneSelectorSize: CGFloat = 45

  // MARK: - Button Size Calculation

  /// Calculates button size based on available geometry and theme
  static func calculateButtonSize(for geometry: GeometryProxy, theme: Theme) -> CGFloat {
    let availableWidth = geometry.size.width - (theme.spacing.medium * 2)
    let spacing: CGFloat = CGFloat(gridColumns - 1) * theme.spacing.small
    return max(
      minButtonSize,
      min(maxButtonSize, (availableWidth - spacing) / CGFloat(gridColumns))
    )
  }
}

// MARK: - Button Size Cache

/// Cached button size manager for performance optimization
final class EmojiButtonSizeCache {
  @MainActor static let shared = EmojiButtonSizeCache()

  private var cachedSize: CGFloat?
  private var lastGeometrySize: CGSize?
  private var lastMediumSpacing: CGFloat?
  private var lastSmallSpacing: CGFloat?

  private init() {}

  @MainActor func buttonSize(for geometry: GeometryProxy, theme: Theme) -> CGFloat {
    // Check if cache is still valid
    if let cached = cachedSize,
      let lastSize = lastGeometrySize,
      let lastMedium = lastMediumSpacing,
      let lastSmall = lastSmallSpacing,
      lastSize == geometry.size,
      lastMedium == theme.spacing.medium,
      lastSmall == theme.spacing.small {
      return cached
    }

    // Calculate and cache new value
    let calculatedSize = EmojiLayout.calculateButtonSize(for: geometry, theme: theme)
    cachedSize = calculatedSize
    lastGeometrySize = geometry.size
    lastMediumSpacing = theme.spacing.medium
    lastSmallSpacing = theme.spacing.small

    return calculatedSize
  }

  @MainActor func invalidateCache() {
    cachedSize = nil
    lastGeometrySize = nil
    lastMediumSpacing = nil
    lastSmallSpacing = nil
  }
}

// MARK: - Convenience Extension

extension EmojiLayout {
  /// Cached button size calculation - avoids repeated geometry calculations during scroll
  @MainActor static func cachedButtonSize(for geometry: GeometryProxy, theme: Theme) -> CGFloat {
    return EmojiButtonSizeCache.shared.buttonSize(for: geometry, theme: theme)
  }
}
