import SwiftUI

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .categoryPillStyle(isSelected: isSelected)
    }
}
