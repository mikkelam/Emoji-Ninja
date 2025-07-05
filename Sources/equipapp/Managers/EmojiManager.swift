import AppKit
@preconcurrency import Combine
@preconcurrency import HotKey
import SwiftUI
import equiplib

@MainActor
class EmojiManager: ObservableObject {
    @Published var isPickerShowing = false
    @Published var selectedSkinTone: SkinTone = .default
    @Published var shouldResetSearch = false

    private var pickerWindow: NSWindow?
    private nonisolated(unsafe) var showPickerHotKey: HotKey?
    private nonisolated(unsafe) var themeObserver: AnyCancellable?

    init() {
        setupHotKey()
        setupThemeObserver()
    }

    func showPicker() {
        if pickerWindow == nil {
            createPickerWindow()
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
        let windowSize = calculateOptimalWindowSize()
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

        pickerWindow?.title = "E-quip Emoji Picker"
        pickerWindow?.contentView = NSHostingView(rootView: contentView)
        pickerWindow?.level = .floating
        pickerWindow?.isReleasedWhenClosed = false

        setupWindowObservers()
    }

    private func calculateOptimalWindowSize() -> CGSize {
        // Get screen where cursor is located
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let currentScreen =
            screens.first { screen in
                NSPointInRect(mouseLocation, screen.frame)
            } ?? NSScreen.main ?? screens.first!

        // Calculate 30% of screen width
        let screenWidth = currentScreen.frame.width
        let pickerWidth = screenWidth * 0.3

        // Set height based on 3:2 aspect ratio (width:height)
        let pickerHeight = pickerWidth * (2.0 / 3.0)

        return CGSize(width: pickerWidth, height: pickerHeight)
    }

    private func positionWindowAtCursor(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = window.frame

        let newOrigin = CGPoint(
            x: mouseLocation.x - windowFrame.width / 2,
            y: mouseLocation.y - windowFrame.height / 2
        )

        window.setFrameOrigin(constrainToScreen(point: newOrigin, windowSize: windowFrame.size))
    }

    private func constrainToScreen(point: CGPoint, windowSize: CGSize) -> CGPoint {
        guard let screen = NSScreen.main else { return point }

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
        copyToClipboard(emoji)
        hidePicker()
        showBriefFeedback(emoji: emoji)
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
