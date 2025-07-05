import AppKit
@preconcurrency import Combine
@preconcurrency import HotKey
import SwiftUI
import ninjalib

@MainActor
class EmojiManager: ObservableObject {
    @Published var isPickerShowing = false
    @Published var selectedSkinTone: SkinTone = .default
    @Published var shouldResetSearch = false

    private var pickerWindow: NSWindow?
    private nonisolated(unsafe) var showPickerHotKey: HotKey?
    private nonisolated(unsafe) var themeObserver: AnyCancellable?
    private var previousApp: NSRunningApplication?
    private var lastScreenFrame: CGRect?

    init() {
        setupHotKey()
        setupThemeObserver()
    }

    func showPicker() {
        // Store the currently focused app before showing picker
        previousApp = NSWorkspace.shared.frontmostApplication

        // Get current screen
        let currentScreen = getCurrentScreen()

        // Recreate window if screen changed or doesn't exist
        if pickerWindow == nil || lastScreenFrame != currentScreen.frame {
            if pickerWindow != nil {
                pickerWindow?.close()
                pickerWindow = nil
            }
            createPickerWindow()
            lastScreenFrame = currentScreen.frame
        }

        guard let window = pickerWindow else { return }

        if window.isVisible {
            hidePicker()
            return
        }

        positionWindowAtCursor(window)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Reset search and selection when showing
        shouldResetSearch = true
        isPickerShowing = true
    }

    func hidePicker() {
        pickerWindow?.close()
        isPickerShowing = false
    }

    private func createPickerWindow() {
        let currentScreen = getCurrentScreen()
        let windowSize = calculateOptimalWindowSize(for: currentScreen)
        let contentView = EmojiPickerView(
            windowSize: windowSize,
            onEmojiSelected: { [weak self] emoji in
                self?.handleEmojiSelection(emoji)
            },
            emojiManager: self
        )
        .themedEnvironment(ThemeManager.shared)

        pickerWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        pickerWindow?.title = "Emoji Ninja"
        pickerWindow?.contentView = NSHostingView(rootView: contentView)
        pickerWindow?.level = .floating
        pickerWindow?.isReleasedWhenClosed = false

        setupWindowObservers()
    }

    private func getCurrentScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        return screens.first { screen in
            NSPointInRect(mouseLocation, screen.frame)
        } ?? NSScreen.main ?? screens.first!
    }

    private func calculateOptimalWindowSize(for screen: NSScreen) -> CGSize {
        // Calculate width based on screen size
        let screenWidth = screen.frame.width
        let widthPercentage = screenWidth < 1800 ? 0.35 : 0.3
        let pickerWidth = screenWidth * widthPercentage

        // Set height based on 4:3 aspect ratio (width:height)
        let pickerHeight = pickerWidth * (3.0 / 4.0)

        return CGSize(width: pickerWidth, height: pickerHeight)
    }

    private func positionWindowAtCursor(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = window.frame
        let currentScreen = getCurrentScreen()

        let newOrigin = CGPoint(
            x: mouseLocation.x - windowFrame.width / 2,
            y: mouseLocation.y - windowFrame.height / 2
        )

        window.setFrameOrigin(
            constrainToScreen(point: newOrigin, windowSize: windowFrame.size, screen: currentScreen)
        )
    }

    private func constrainToScreen(point: CGPoint, windowSize: CGSize, screen: NSScreen) -> CGPoint
    {

        let screenFrame = screen.visibleFrame
        var constrainedPoint = point

        // Keep window on screen
        if constrainedPoint.x + windowSize.width > screenFrame.maxX {
            constrainedPoint.x = screenFrame.maxX - windowSize.width
        }
        if constrainedPoint.x < screenFrame.minX {
            constrainedPoint.x = screenFrame.minX
        }
        if constrainedPoint.y + windowSize.height > screenFrame.maxY {
            constrainedPoint.y = screenFrame.maxY - windowSize.height
        }
        if constrainedPoint.y < screenFrame.minY {
            constrainedPoint.y = screenFrame.minY
        }

        return constrainedPoint
    }

    private func setupWindowObservers() {
        guard let window = pickerWindow else { return }

        // Close window when it loses focus
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let window = self?.pickerWindow, !window.isKeyWindow {
                    self?.hidePicker()
                }
            }
        }
    }

    private func handleEmojiSelection(_ emoji: String) {
        FrequentlyUsedEmojiManager.shared.recordEmojiUsage(emoji)
        hidePicker()

        // Brief delay to allow focus to return to previous app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.typeEmojiDirectly(emoji)
        }

        showBriefFeedback(emoji: emoji)
    }

    private func typeEmojiDirectly(_ emoji: String) {
        // Check if we have accessibility permissions
        if !AXIsProcessTrusted() {
            print("❌ No accessibility permissions. Cannot type emoji.")
            copyToClipboard(emoji)
            return
        }

        // Restore focus to previous app first
        if let app = previousApp {
            app.activate(options: [])
            print("🔄 Restored focus to \(app.localizedName ?? "Unknown")")
        }

        self.typeUnicodeDirectly(emoji)

    }

    private func typeUnicodeDirectly(_ emoji: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("❌ Failed to create CGEventSource")
            return
        }

        // Convert emoji to UTF-16 and type it directly
        let utf16 = Array(emoji.utf16)

        if let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
            event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            event.post(tap: .cgSessionEventTap)
        }

        print("⌨️ Typed emoji directly: \(emoji)")
    }

    private func promptForAccessibilityPermissions() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText =
            "Emoji Ninja needs accessibility permissions to type emojis directly into other apps. Please enable it in System Settings > Privacy & Security > Accessibility."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(
                    string:
                        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                )!)
        }
    }

    private func copyToClipboard(_ emoji: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(emoji, forType: .string)
    }

    private func showBriefFeedback(emoji: String) {
        // Simple console feedback - could be enhanced with toast notification
    }

    private func setupHotKey() {
        showPickerHotKey = HotKey(key: .space, modifiers: [.command, .control])
        showPickerHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.showPicker()
            }
        }
    }

    private func setupThemeObserver() {
        themeObserver = ThemeManager.shared.$currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recreatePickerWindowIfNeeded()
            }
    }

    private func recreatePickerWindowIfNeeded() {
        if pickerWindow != nil {
            pickerWindow?.close()
            pickerWindow = nil
        }
    }

    deinit {
        showPickerHotKey = nil
        themeObserver?.cancel()
    }
}
