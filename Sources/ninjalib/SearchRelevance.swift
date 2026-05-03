import Foundation

struct SearchStatsArtifact: Codable {
  let version: Int
  let generatedAt: String
  let emojiCount: Int
  let frequentTags: [String]
  let frequentLabelTokens: [String]
  let tagFrequencies: [String: Int]
  let labelTokenFrequencies: [String: Int]
}

enum SearchRelevance {
  static let shared = SearchRelevanceModel.load()
}

struct SearchRelevanceModel {
  let frequentTags: Set<String>
  let frequentLabelTokens: Set<String>
  let tagFrequencies: [String: Int]
  let labelTokenFrequencies: [String: Int]

  static func load() -> SearchRelevanceModel {
    guard
      let url = Bundle.module.url(forResource: "search_stats", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let artifact = try? JSONDecoder().decode(SearchStatsArtifact.self, from: data)
    else {
      return SearchRelevanceModel(
        frequentTags: [],
        frequentLabelTokens: [],
        tagFrequencies: [:],
        labelTokenFrequencies: [:]
      )
    }

    return SearchRelevanceModel(
      frequentTags: Set(artifact.frequentTags),
      frequentLabelTokens: Set(artifact.frequentLabelTokens),
      tagFrequencies: artifact.tagFrequencies,
      labelTokenFrequencies: artifact.labelTokenFrequencies
    )
  }

  func score(emoji: EmojibaseEmoji, query: String) -> Int {
    let normalizedQuery = normalize(query)
    guard !normalizedQuery.isEmpty else { return 0 }

    let label = normalize(emoji.label)
    let tags = (emoji.tags ?? []).map(normalize)
    let queryTokens = tokenize(normalizedQuery)
    let labelTokens = Set(tokenize(label))
    let tagTokens = Set(tags.flatMap(tokenize))

    return phraseScore(label: label, tags: tags, normalizedQuery: normalizedQuery)
      + tokenScore(queryTokens: queryTokens, labelTokens: labelTokens, tagTokens: tagTokens)
  }

  private func normalize(_ text: String) -> String {
    text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
  }

  private func tokenize(_ text: String) -> [String] {
    text
      .split { !$0.isLetter && !$0.isNumber }
      .map(String.init)
      .filter { !$0.isEmpty }
  }

  private func tokenUnitWeight(_ token: String) -> Int {
    switch token.count {
    case 0...2:
      return 1
    case 3...4:
      return 2
    case 5...7:
      return 3
    default:
      return 4
    }
  }

  private func phraseScore(label: String, tags: [String], normalizedQuery: String) -> Int {
    var score = 0
    if label == normalizedQuery { score += 5000 }
    if tags.contains(normalizedQuery) { score += 4200 }
    if label.hasPrefix(normalizedQuery) { score += 2600 }
    if tags.contains(where: { $0.hasPrefix(normalizedQuery) }) { score += 2200 }
    if label.contains(normalizedQuery) { score += 1000 }
    if tags.contains(where: { $0.contains(normalizedQuery) }) { score += 800 }
    return score
  }

  private func tokenScore(
    queryTokens: [String],
    labelTokens: Set<String>,
    tagTokens: Set<String>
  ) -> Int {
    var score = 0
    for token in queryTokens {
      let unit = tokenUnitWeight(token)

      if labelTokens.contains(token) { score += 450 * unit }
      if tagTokens.contains(token) { score += 550 * unit }

      if frequentLabelTokens.contains(token) { score -= 90 * unit }
      if frequentTags.contains(token) { score -= 120 * unit }

      if let freq = tagFrequencies[token], freq <= 5 { score += 120 * unit }
      if let freq = labelTokenFrequencies[token], freq <= 5 { score += 90 * unit }
    }
    return score
  }
}
