import AppKit
import Combine
import SwiftUI

@MainActor
class MenuBarViewModel: ObservableObject {
  @Published var showingLaunchAtLoginAlert = false
  @Published var launchAtLoginError: String?
  @Published var showingAccessibilityDialog = false
  private var accessibilityDialogWindow: NSWindow?

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

    // Observe accessibility permission changes
    appState.$hasAccessibilityPermission
      .sink { [weak self] _ in
        self?.objectWillChange.send()
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

  // MARK: - Accessibility Permissions

  var hasAccessibilityPermission: Bool {
    appState.hasAccessibilityPermission
  }

  func showAccessibilityDialog() {
    createAccessibilityDialogWindow()
    accessibilityDialogWindow?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    showingAccessibilityDialog = true
  }

  func dismissAccessibilityDialog() {
    accessibilityDialogWindow?.close()
    accessibilityDialogWindow = nil
    showingAccessibilityDialog = false
    // Mark as seen when dismissed
    appState.markAccessibilityDialogAsSeen()
  }

  func requestAccessibilityPermissions() {
    appState.requestAccessibilityPermissions()
    dismissAccessibilityDialog()
  }

  func checkAndShowFirstLaunchDialog() {
    if appState.shouldShowAccessibilityDialogOnLaunch() {
      showAccessibilityDialog()
    }
  }

  private func createAccessibilityDialogWindow() {
    let contentView = AccessibilityPermissionDialog(
      onGrantPermission: { [weak self] in
        self?.requestAccessibilityPermissions()
      },
      onDismiss: { [weak self] in
        self?.dismissAccessibilityDialog()
      }
    )
    .themedEnvironment(themeManager)

    accessibilityDialogWindow = NSWindow(
      contentRect: NSRect(origin: .zero, size: CGSize(width: 400, height: 500)),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )

    accessibilityDialogWindow?.title = "Emoji Ninja"
    accessibilityDialogWindow?.contentView = NSHostingView(rootView: contentView)
    accessibilityDialogWindow?.level = .floating
    accessibilityDialogWindow?.center()
    accessibilityDialogWindow?.isReleasedWhenClosed = false
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
