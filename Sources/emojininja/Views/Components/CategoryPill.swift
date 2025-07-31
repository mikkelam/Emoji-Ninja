import SwiftUI

struct CategoryPill: View {
  let title: String
  let emoji: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(emoji)
        .font(.title2)
    }
    .categoryPillStyle(isSelected: isSelected)
    .help(title)
  }
}
