import Foundation
import ninjalib

struct EmojiSectionSnapshot {
  let category: CategoryType
  let emojis: [EmojibaseEmoji]
  let startIndex: Int
}

struct EmojiDataSnapshot {
  let sections: [EmojiSectionSnapshot]
  let flatEmojis: [EmojibaseEmoji]
  let sectionCounts: [Int]

  static var empty: EmojiDataSnapshot {
    EmojiDataSnapshot(sections: [], flatEmojis: [], sectionCounts: [])
  }
}

@MainActor
struct EmojiDataSource {
  private let repository: EmojiRepository

  init(repository: EmojiRepository) {
    self.repository = repository
  }

  func makeSnapshot(searchText: String, selectedCategory: CategoryType?) -> EmojiDataSnapshot {
    if searchText.count >= 2 {
      let results = repository.search(query: searchText)
      return EmojiDataSnapshot(
        sections: [],
        flatEmojis: results,
        sectionCounts: [results.count]
      )
    }

    let categories: [CategoryType]
    if let selectedCategory {
      categories = [selectedCategory]
    } else {
      categories = availableCategories()
    }

    var startIndex = 0
    let sections = categories.compactMap { category -> EmojiSectionSnapshot? in
      let emojis = emojis(for: category)
      guard !emojis.isEmpty else { return nil }
      defer { startIndex += emojis.count }
      return EmojiSectionSnapshot(category: category, emojis: emojis, startIndex: startIndex)
    }

    let flatEmojis = sections.flatMap(\.emojis)
    return EmojiDataSnapshot(
      sections: sections,
      flatEmojis: flatEmojis,
      sectionCounts: sections.map { $0.emojis.count }
    )
  }

  private func availableCategories() -> [CategoryType] {
    var categories: [CategoryType] = []
    if repository.hasFrequentlyUsedEmojis() {
      categories.append(.frequentlyUsed)
    }
    categories.append(contentsOf: EmojiGroup.availableGroups.map { .regular($0) })
    return categories
  }

  private func emojis(for category: CategoryType) -> [EmojibaseEmoji] {
    switch category {
    case .frequentlyUsed:
      return repository.frequentlyUsedEmojis()
    case .regular(let group):
      return repository.emojis(for: group)
    }
  }
}
