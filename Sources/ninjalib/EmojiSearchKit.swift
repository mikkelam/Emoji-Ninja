@preconcurrency import CoreServices
import Foundation

/// A high-performance search engine for emoji data using Apple's SearchKit
@MainActor
public class EmojiSearchKit {
  private var searchIndex: SKIndex?
  private let indexURL: URL
  private var documentURLs: [String: URL] = [:]
  private var emojiMap: [URL: EmojibaseEmoji] = [:]

  // Search options - enable fuzzy matching
  private let searchOptions = SKSearchOptions(
    kSKSearchOptionDefault
      | kSKSearchOptionFindSimilar
      | kSKSearchOptionSpaceMeansOR
  )

  public init() {
    // Create index in memory (you can also persist to disk)
    let tempDir = FileManager.default.temporaryDirectory
    self.indexURL = tempDir.appendingPathComponent("emoji_search_index_\(UUID().uuidString)")

    createIndex()
  }

  deinit {
    // Clean up temp file if it exists
    try? FileManager.default.removeItem(at: indexURL)
  }

  // MARK: - Index Management

  private func createIndex() {
    // Create search index with custom properties for better emoji searching
    let properties =
      [
        kSKProximityIndexing: true,  // Enable proximity searching
        kSKMinTermLength: 1,  // Allow single character searches
        kSKMaximumTerms: 2000,  // Plenty of terms for tags
      ] as CFDictionary

    // Create the index
    if let index = SKIndexCreateWithURL(
      indexURL as CFURL,
      nil,  // No index name needed for file-based
      SKIndexType(kSKIndexInverted.rawValue),
      properties
    ) {
      self.searchIndex = index.takeRetainedValue()
    } else {
      print("❌ Failed to create SearchKit index")
    }
  }

  // MARK: - Indexing

  func indexEmojis(_ emojis: [EmojibaseEmoji]) {
    guard let index = searchIndex else { return }

    for emoji in emojis {
      // Create a unique URL for this emoji
      let documentURL = URL(string: "emoji://\(emoji.hexcode)")!

      // Build searchable text from all emoji properties
      var searchableText = [emoji.label]

      if let tags = emoji.tags {
        searchableText.append(contentsOf: tags)
      }

      if let emoticons = emoji.emoticon?.values {
        searchableText.append(contentsOf: emoticons)
      }

      // Add hexcode for technical searches
      searchableText.append(emoji.hexcode)

      // Join all searchable content
      let fullText = searchableText.joined(separator: " ")

      // Create document
      if let document = SKDocumentCreateWithURL(documentURL as CFURL) {
        // Index the document
        let added = SKIndexAddDocumentWithText(
          index,
          document.takeRetainedValue(),
          fullText as CFString,
          true  // Can replace existing
        )

        if added {
          // Store mappings for retrieval
          documentURLs[emoji.hexcode] = documentURL
          emojiMap[documentURL] = emoji
        }
      }
    }

    // Flush the index to ensure all documents are searchable
    SKIndexFlush(index)
  }

  // MARK: - Searching

  public struct SearchResult {
    public let emoji: EmojibaseEmoji
    public let score: Float
    public let matchedTerms: [String]
  }

  public func search(query: String, limit: Int = 50) -> [SearchResult] {
    guard let index = searchIndex,
      !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return []
    }

    // First try exact search
    var results = performSearch(query: query, index: index, limit: limit)

    // For better substring matching, always try wildcard searches
    if query.count >= 2 {
      // Try prefix matching
      let prefixQuery = "\(query)*"
      let prefixResults = performSearch(query: prefixQuery, index: index, limit: limit)
      results = mergeResults(results, prefixResults)

      // Try substring matching with wildcards around the query
      let substringQuery = "*\(query)*"
      let substringResults = performSearch(query: substringQuery, index: index, limit: limit)
      results = mergeResults(results, substringResults)

      // If still limited results, try each word with wildcards
      if results.count < limit / 2 {
        let words = query.split(separator: " ").map(String.init)
        let wildcardQuery = words.map { "*\($0)*" }.joined(separator: " ")
        let wildcardResults = performSearch(
          query: wildcardQuery, index: index, limit: limit)
        results = mergeResults(results, wildcardResults)
      }
    }

    return results
  }

  private func performSearch(query: String, index: SKIndex, limit: Int) -> [SearchResult] {
    // Create search
    guard
      let searchRef = SKSearchCreate(
        index,
        query as CFString,
        searchOptions
      )
    else {
      return []
    }

    let search = searchRef.takeRetainedValue()

    var results: [SearchResult] = []
    let maxResults = limit
    var documentIDs = [SKDocumentID](repeating: 0, count: maxResults)
    var scores = [Float](repeating: 0, count: maxResults)
    var foundCount = 0

    // Perform search
    _ = SKSearchFindMatches(
      search,
      maxResults,
      &documentIDs,
      &scores,
      CFTimeInterval(0.1),  // 100ms timeout
      &foundCount
    )

    // Process results
    for i in 0..<foundCount {
      let docID = documentIDs[i]

      // Get document URL
      if let documentRef = SKIndexCopyDocumentForDocumentID(index, docID) {
        let document = documentRef.takeRetainedValue()
        if let url = SKDocumentCopyURL(document) {
          let documentURL = url.takeRetainedValue() as URL

          if let emoji = emojiMap[documentURL] {
            // Extract matched terms (this is a simplified version)
            let matchedTerms = extractMatchedTerms(query: query, emoji: emoji)

            results.append(
              SearchResult(
                emoji: emoji,
                score: scores[i],
                matchedTerms: matchedTerms
              ))
          }
        }
      }
    }

    // Sort by score (highest first)
    results.sort { $0.score > $1.score }

    return results
  }

  // MARK: - Helper Methods

  private func mergeResults(_ existing: [SearchResult], _ new: [SearchResult]) -> [SearchResult] {
    var merged = existing
    let existingHexcodes = Set(existing.map { $0.emoji.hexcode })

    for result in new {
      if !existingHexcodes.contains(result.emoji.hexcode) {
        merged.append(result)
      }
    }

    return merged
  }

  private func extractMatchedTerms(query: String, emoji: EmojibaseEmoji) -> [String] {
    let queryTerms = query.lowercased().split(separator: " ").map(String.init)
    var matched: Set<String> = []

    // Check label
    let labelLower = emoji.label.lowercased()
    for term in queryTerms {
      if labelLower.contains(term) {
        matched.insert(emoji.label)
      }
    }

    // Check tags
    if let tags = emoji.tags {
      for tag in tags {
        let tagLower = tag.lowercased()
        for term in queryTerms {
          if tagLower.contains(term) {
            matched.insert(tag)
          }
        }
      }
    }

    return Array(matched)
  }

  // MARK: - Advanced Search Features

  /// Search with additional options
  func advancedSearch(
    query: String,
    categories: [EmojiGroup]? = nil,
    excludeTerms: [String]? = nil,
    limit: Int = 50
  ) -> [SearchResult] {
    var searchQuery = query

    // Add exclusions using SearchKit syntax
    if let excludeTerms = excludeTerms, !excludeTerms.isEmpty {
      let exclusions = excludeTerms.map { "NOT \($0)" }.joined(separator: " ")
      searchQuery += " \(exclusions)"
    }

    var results = search(query: searchQuery, limit: limit * 2)  // Get more results for filtering

    // Filter by categories if specified
    if let categories = categories, !categories.isEmpty {
      let allowedGroups = Set(
        categories.compactMap { category -> Int? in
          return category.rawValue
        })

      results = results.filter { result in
        if let group = result.emoji.group {
          return allowedGroups.contains(group)
        }
        return false
      }
    }

    // Limit final results
    return Array(results.prefix(limit))
  }

  /// Get similar emojis based on an example
  func findSimilar(to emoji: EmojibaseEmoji, limit: Int = 20) -> [SearchResult] {
    // Use emoji's label and first few tags as the search query
    var searchTerms = [emoji.label]
    if let tags = emoji.tags {
      searchTerms.append(contentsOf: tags.prefix(3))
    }

    let query = searchTerms.joined(separator: " OR ")
    var results = search(query: query, limit: limit + 1)

    // Remove the original emoji from results
    results.removeAll { $0.emoji.hexcode == emoji.hexcode }

    return results
  }

  // MARK: - Index Statistics

  var indexedDocumentCount: Int {
    guard let index = searchIndex else { return 0 }
    return SKIndexGetDocumentCount(index)
  }

  var indexSize: Int64 {
    guard FileManager.default.fileExists(atPath: indexURL.path) else { return 0 }

    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: indexURL.path)
      return attributes[.size] as? Int64 ?? 0
    } catch {
      return 0
    }
  }
}

// MARK: - Integration with EmojiDataManager

extension EmojiDataManager {
  @MainActor private static var searchKitInstance: EmojiSearchKit?

  /// Get or create the SearchKit instance
  @MainActor
  static var searchKit: EmojiSearchKit {
    if searchKitInstance == nil {
      let kit = EmojiSearchKit()
      // Index all supported emojis
      kit.indexEmojis(shared.getSupportedEmojis())
      searchKitInstance = kit
    }
    return searchKitInstance!
  }

  /// Enhanced search using SearchKit with fallback to manual substring search
  @MainActor
  public func searchEmojisWithSearchKit(query: String) -> [EmojibaseEmoji] {
    guard !query.isEmpty else { return [] }

    let searchKitResults = Self.searchKit.search(query: query)
    var results = searchKitResults.map { $0.emoji }

    // Always supplement with manual substring search to ensure comprehensive results
    let allEmojis = getAllEmojis()
    let lowercaseQuery = query.lowercased()

    let additionalResults = allEmojis.filter { emoji in
      // Skip if already found by SearchKit
      if results.contains(where: { $0.hexcode == emoji.hexcode }) {
        return false
      }

      // Check if query matches label or any tag as substring
      let labelMatch = emoji.label.lowercased().contains(lowercaseQuery)
      let tagMatch =
        emoji.tags?.contains { tag in
          tag.lowercased().contains(lowercaseQuery)
        } ?? false

      return labelMatch || tagMatch
    }

    results.append(contentsOf: additionalResults)

    // Limit total results for performance (SearchKit results first, then substring matches)
    return Array(results.prefix(100))
  }

}
