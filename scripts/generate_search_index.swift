import Foundation

struct Emoji: Decodable {
  let hexcode: String
  let label: String
  let unicode: String
  let group: Int?
  let order: Int?
  let tags: [String]?
  let emoticon: Emoticon?

  enum Emoticon: Decodable {
    case single(String)
    case multiple([String])

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let value = try? container.decode(String.self) {
        self = .single(value)
        return
      }
      self = .multiple(try container.decode([String].self))
    }

    var values: [String] {
      switch self {
      case .single(let value):
        return [value]
      case .multiple(let values):
        return values
      }
    }
  }
}

struct SearchIndexArtifact: Encodable {
  let version: Int
  let generatedAt: String
  let emojiCount: Int
  let entries: [Entry]

  struct Entry: Encodable {
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
}

private func normalize(_ text: String) -> String {
  text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private func tokenize(_ text: String) -> [String] {
  normalize(text)
    .split { !$0.isLetter && !$0.isNumber }
    .map(String.init)
    .filter { !$0.isEmpty }
}

private func aliases(for emoji: Emoji, label: String) -> [String] {
  var result: Set<String> = []

  if label.hasPrefix("keycap: ") {
    let suffix = String(label.dropFirst("keycap: ".count))
    result.insert(suffix)
    result.insert("keycap \(suffix)")
  }

  for emoticon in emoji.emoticon?.values ?? [] {
    result.insert(normalize(emoticon))
  }

  return result.filter { !$0.isEmpty }.sorted()
}

let args = CommandLine.arguments
guard args.count == 3 else {
  fputs("usage: swift scripts/generate_search_index.swift <input-emoji-json> <output-json>\n", stderr)
  exit(2)
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])

let data = try Data(contentsOf: inputURL)
let emojis = try JSONDecoder().decode([Emoji].self, from: data)

let entries = emojis.map { emoji in
  let normalizedLabel = normalize(emoji.label)
  let normalizedTags = (emoji.tags ?? []).map(normalize)
  let normalizedEmoticons = (emoji.emoticon?.values ?? []).map(normalize)

  let tokenSet = Set(
    tokenize(normalizedLabel)
      + normalizedTags.flatMap(tokenize)
      + normalizedEmoticons.flatMap(tokenize)
  )

  return SearchIndexArtifact.Entry(
    hexcode: emoji.hexcode,
    label: normalizedLabel,
    unicode: emoji.unicode,
    group: emoji.group,
    order: emoji.order,
    tags: normalizedTags,
    emoticons: normalizedEmoticons,
    tokens: tokenSet.sorted(),
    aliases: aliases(for: emoji, label: normalizedLabel)
  )
}

let artifact = SearchIndexArtifact(
  version: 1,
  generatedAt: ISO8601DateFormatter().string(from: Date()),
  emojiCount: entries.count,
  entries: entries
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let encoded = try encoder.encode(artifact)

try FileManager.default.createDirectory(
  at: outputURL.deletingLastPathComponent(),
  withIntermediateDirectories: true
)
try encoded.write(to: outputURL, options: .atomic)

print("wrote search index: \(outputURL.path)")
