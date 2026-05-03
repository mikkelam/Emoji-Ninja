import Foundation

@MainActor
public class EmojiSearchKit {
  private let entries: [SearchEntry]
  private let artifactBytes: Int64

  public init(emojis: [EmojibaseEmoji]) {
    let artifact = SearchIndexArtifact.load()
    let allowed = Set(emojis.map(\.hexcode))
    let emojiByHex = Dictionary(uniqueKeysWithValues: emojis.map { ($0.hexcode, $0) })

    var builtEntries: [SearchEntry] = []
    builtEntries.reserveCapacity(artifact.entries.count)

    for entry in artifact.entries where allowed.contains(entry.hexcode) {
      guard let emoji = emojiByHex[entry.hexcode] else { continue }
      builtEntries.append(SearchEntry(artifact: entry, emoji: emoji))
    }

    entries = builtEntries
    artifactBytes = artifact.byteSizeEstimate
  }

  public struct SearchResult {
    public let emoji: EmojibaseEmoji
    public let score: Float
  }

  public func search(query: String, limit: Int = 50) -> [SearchResult] {
    let normalized = normalizeSearchText(query)
    guard !normalized.isEmpty else { return [] }

    let queryTokens = tokenizeSearchText(normalized)
    var scored: [(entry: SearchEntry, score: Int)] = []

    scored.reserveCapacity(entries.count / 3)

    for entry in entries {
      let score = score(entry: entry, query: normalized, queryTokens: queryTokens)
      if score > 0 {
        scored.append((entry, score))
      }
    }

    scored.sort { lhs, rhs in
      if lhs.score != rhs.score { return lhs.score > rhs.score }
      if lhs.entry.order != rhs.entry.order { return lhs.entry.order < rhs.entry.order }
      return lhs.entry.hexcode < rhs.entry.hexcode
    }

    return scored.prefix(limit).map {
      SearchResult(emoji: $0.entry.emoji, score: Float($0.score))
    }
  }

  private func score(
    entry: SearchEntry,
    query: String,
    queryTokens: [String]
  ) -> Int {
    var score = 0
    let isSingleCharacter = query.count == 1

    if entry.unicode == query {
      score += 30_000
    }
    if entry.hexcode == query {
      score += 28_000
    }
    if entry.aliases.contains(query) {
      score += 26_000
    }
    if entry.label == query {
      score += 20_000
    }
    if entry.tags.contains(query) {
      score += 18_000
    }
    if entry.tokens.contains(query) {
      score += 16_000
    }

    if isSingleCharacter {
      return score
    }

    if entry.label.hasPrefix(query) {
      score += 10_000
    }
    if entry.tags.contains(where: { $0.hasPrefix(query) }) {
      score += 9_000
    }
    if entry.label.contains(query) {
      score += 4_500
    }
    if entry.tags.contains(where: { $0.contains(query) }) {
      score += 4_000
    }

    for token in queryTokens {
      if entry.tokens.contains(token) {
        score += 1_500
      }
    }

    return score
  }

  var indexedDocumentCount: Int {
    entries.count
  }

  var indexSize: Int64 {
    artifactBytes
  }
}

private struct SearchEntry {
  let emoji: EmojibaseEmoji
  let hexcode: String
  let label: String
  let unicode: String
  let tags: [String]
  let tokens: Set<String>
  let aliases: Set<String>
  let order: Int

  init(artifact: SearchIndexArtifact.Entry, emoji: EmojibaseEmoji) {
    self.emoji = emoji
    hexcode = artifact.hexcode
    label = artifact.label
    unicode = artifact.unicode
    tags = artifact.tags
    tokens = Set(artifact.tokens)
    aliases = Set(artifact.aliases)
    order = artifact.order ?? Int.max
  }
}

private struct SearchIndexArtifact: Codable {
  struct Entry: Codable {
    let hexcode: String
    let label: String
    let unicode: String
    let group: Int?
    let order: Int?
    let tags: [String]
    let emoticons: [String]
    let tokens: [String]
    let aliases: [String]
  }

  let version: Int
  let generatedAt: String
  let emojiCount: Int
  let entries: [Entry]

  static func load() -> SearchIndexArtifact {
    guard
      let url = Bundle.module.url(forResource: "search_index", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let artifact = try? JSONDecoder().decode(SearchIndexArtifact.self, from: data)
    else {
      return SearchIndexArtifact(version: 1, generatedAt: "", emojiCount: 0, entries: [])
    }
    return artifact
  }

  var byteSizeEstimate: Int64 {
    Int64(entries.count * 120)
  }
}

extension EmojiDataManager {
  @MainActor private static var searchKitInstance: EmojiSearchKit?
  private static let maxSearchResults = 100

  @MainActor
  static var searchKit: EmojiSearchKit {
    if searchKitInstance == nil {
      searchKitInstance = EmojiSearchKit(emojis: shared.getSupportedEmojis())
    }
    return searchKitInstance!
  }

  @MainActor
  public func searchEmojisWithSearchKit(query: String) -> [EmojibaseEmoji] {
    Array(Self.searchKit.search(query: query, limit: Self.maxSearchResults).map(\.emoji))
  }
}

private func normalizeSearchText(_ text: String) -> String {
  text
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .lowercased()
}

private func tokenizeSearchText(_ text: String) -> [String] {
  text
    .split { !$0.isLetter && !$0.isNumber }
    .map(String.init)
    .filter { !$0.isEmpty }
}
