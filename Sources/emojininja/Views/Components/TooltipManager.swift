import SwiftUI
import ninjalib

@MainActor
class TooltipManager: ObservableObject {
  @Published var isVisible = false
  @Published var text = ""
  @Published var position = CGPoint.zero

  func showTooltip(_ text: String, at frame: CGRect) {
    self.text = text

    let offset: CGFloat = 16

    // Position tooltip with top edge just below button
    self.position = CGPoint(
      x: frame.midX,
      y: frame.maxY + offset
    )
    self.isVisible = true
  }

  func hideTooltip() {
    self.isVisible = false
  }
}

struct GlobalTooltipView: View {
  @ObservedObject var tooltipManager: TooltipManager
  @Environment(\.theme) private var theme

  var body: some View {
    if tooltipManager.isVisible {
      Text(tooltipManager.text)
        .tooltipStyle()
        .position(x: tooltipManager.position.x, y: tooltipManager.position.y)
        .transition(.identity)
        .zIndex(1000)
    }
  }
}
