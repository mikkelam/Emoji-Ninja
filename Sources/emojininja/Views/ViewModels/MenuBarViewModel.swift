import Combine
import SwiftUI

@MainActor
class MenuBarViewModel: ObservableObject {
    @Published var showingLaunchAtLoginAlert = false
    @Published var launchAtLoginError: String?

    private let appState: AppState
    private let emojiManager: EmojiManager
    private let themeManager: ThemeManager
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState, emojiManager: EmojiManager, themeManager: ThemeManager) {
        self.appState = appState
        self.emojiManager = emojiManager
        self.themeManager = themeManager
        setupObservers()
    }

    private func setupObservers() {
        // Observe launch at login errors
        appState.$launchAtLoginError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.launchAtLoginError = error
                self?.showingLaunchAtLoginAlert = true
            }
            .store(in: &cancellables)
    }

    // MARK: - Emoji Actions

    func showEmojiPicker() {
        emojiManager.showPicker()
    }

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get { appState.launchAtLogin }
        set { appState.launchAtLogin = newValue }
    }

    func dismissLaunchAtLoginAlert() {
        showingLaunchAtLoginAlert = false
        launchAtLoginError = nil
    }

    // MARK: - Theme Management

    var currentTheme: ThemeType {
        themeManager.themeType
    }

    func setTheme(_ theme: ThemeType) {
        themeManager.setTheme(theme)
    }

    func isCurrentTheme(_ theme: ThemeType) -> Bool {
        themeManager.themeType == theme
    }

    // MARK: - App Lifecycle

    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
