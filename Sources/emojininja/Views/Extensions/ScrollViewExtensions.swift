import SwiftUI
import ninjalib

// MARK: - Emoji-Specific Scroll Extensions

extension View {
    /// Tracks scrolling state for emoji picker views
    func trackEmojiScrolling(isScrolling: Binding<Bool>) -> some View {
        self.modifier(EmojiScrollTrackingModifier(isScrolling: isScrolling))
    }
}

// MARK: - Emoji Scroll Tracking Modifier

struct EmojiScrollTrackingModifier: ViewModifier {
    @Binding var isScrolling: Bool
    @State private var lastScrollPosition: CGPoint = .zero
    @State private var scrollDebounceTimer: Timer?

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: EmojiScrollPositionPreferenceKey.self,
                            value: geometry.frame(in: .named("emojiScrollCoordinate")).origin
                        )
                }
            )
            .coordinateSpace(name: "emojiScrollCoordinate")
            .onPreferenceChange(EmojiScrollPositionPreferenceKey.self) { position in
                Task { @MainActor in
                    handleScrollPositionChange(position)
                }
            }
    }

    @MainActor
    private func handleScrollPositionChange(_ position: CGPoint) {
        let hasScrolled = position != lastScrollPosition

        if hasScrolled {
            if !isScrolling {
                DispatchQueue.main.async {
                    isScrolling = true
                }
            }

            scrollDebounceTimer?.invalidate()
            scrollDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                DispatchQueue.main.async {
                    isScrolling = false
                }
            }

            lastScrollPosition = position
        }
    }
}

// MARK: - Emoji Scroll Preference Key

struct EmojiScrollPositionPreferenceKey: PreferenceKey {
    static let defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}
