import Foundation

struct Emoji: Decodable {
  let label: String
  let tags: [String]?
}

struct SearchStats: Encodable {
  let version: Int
  let generatedAt: String
  let emojiCount: Int
  let frequentTags: [String]
  let frequentLabelTokens: [String]
  let tagFrequencies: [String: Int]
  let labelTokenFrequencies: [String: Int]
}

private func tokenize(_ text: String) -> [String] {
  text
    .lowercased()
    .split { !$0.isLetter && !$0.isNumber }
    .map(String.init)
    .filter { $0.count >= 2 }
}

private func topKeys(
  _ frequencies: [String: Int],
  minCount: Int,
  limit: Int
) -> [String] {
  frequencies
    .filter { $0.value >= minCount }
    .sorted {
      if $0.value == $1.value { return $0.key < $1.key }
      return $0.value > $1.value
    }
    .prefix(limit)
    .map(\.key)
}

let args = CommandLine.arguments
guard args.count == 3 else {
  fputs("usage: swift scripts/generate_search_stats.swift <input-emoji-json> <output-json>\n", stderr)
  exit(2)
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])

let data = try Data(contentsOf: inputURL)
let emojis = try JSONDecoder().decode([Emoji].self, from: data)

var tagFrequencies: [String: Int] = [:]
var labelTokenFrequencies: [String: Int] = [:]

for emoji in emojis {
  for token in tokenize(emoji.label) {
    labelTokenFrequencies[token, default: 0] += 1
  }

  guard let tags = emoji.tags else { continue }
  for tag in tags {
    for token in tokenize(tag) {
      tagFrequencies[token, default: 0] += 1
    }
  }
}

let stats = SearchStats(
  version: 1,
  generatedAt: ISO8601DateFormatter().string(from: Date()),
  emojiCount: emojis.count,
  frequentTags: topKeys(tagFrequencies, minCount: 20, limit: 128),
  frequentLabelTokens: topKeys(labelTokenFrequencies, minCount: 20, limit: 128),
  tagFrequencies: tagFrequencies,
  labelTokenFrequencies: labelTokenFrequencies
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let encoded = try encoder.encode(stats)

try FileManager.default.createDirectory(
  at: outputURL.deletingLastPathComponent(),
  withIntermediateDirectories: true
)
try encoded.write(to: outputURL, options: .atomic)

print("wrote search stats: \(outputURL.path)")
