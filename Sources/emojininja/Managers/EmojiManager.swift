import AppKit
import Carbon
@preconcurrency import Combine
import SwiftUI
import ninjalib

@MainActor
class EmojiManager: ObservableObject {
  @Published var isPickerShowing = false
  @Published var selectedSkinTone: SkinTone = .default
  @Published var shouldResetSearch = false

  private var pickerWindow: NSWindow?
  private nonisolated(unsafe) var hotKeyRef: EventHotKeyRef?
  private nonisolated(unsafe) var hotKeyHandlerRef: EventHandlerRef?
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
      onEmojiSelected: { [weak self] emojiData in
        self?.handleEmojiSelection(emojiData)
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
      screen.frame.contains(mouseLocation)
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

  private func constrainToScreen(point: CGPoint, windowSize: CGSize, screen: NSScreen) -> CGPoint {

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

  private func handleEmojiSelection(_ emojiData: EmojibaseEmoji) {
    let emojiWithSkinTone = emojiData.withSkinTone(selectedSkinTone)
    FrequentlyUsedEmojiManager.shared.recordEmojiUsage(emojiWithSkinTone)
    hidePicker()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.typeEmojiDirectly(emojiWithSkinTone)
    }

    showBriefFeedback(emoji: emojiWithSkinTone)
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

  private func copyToClipboard(_ emoji: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(emoji, forType: .string)
  }

  private func showBriefFeedback(emoji: String) {
    // Simple console feedback - could be enhanced with toast notification
  }

  private func setupHotKey() {
    let eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let hotKeyID = EventHotKeyID(signature: OSType(fourCharCode("EMNJ")), id: 1)

    let status = InstallEventHandler(
      GetEventDispatcherTarget(),
      { _, event, userData in
        guard let event else { return noErr }
        var receivedHotKeyID = EventHotKeyID()
        let copyStatus = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &receivedHotKeyID
        )
        guard copyStatus == noErr, receivedHotKeyID.signature == OSType(fourCharCode("EMNJ")),
          receivedHotKeyID.id == 1
        else {
          return noErr
        }
        guard let userData else { return noErr }
        let manager = Unmanaged<EmojiManager>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
          manager.showPicker()
        }
        return noErr
      },
      1,
      [eventType],
      Unmanaged.passUnretained(self).toOpaque(),
      &hotKeyHandlerRef
    )
    guard status == noErr else {
      print("❌ Failed to install hotkey handler: \(status)")
      return
    }

    let registerStatus = RegisterEventHotKey(
      UInt32(kVK_Space),
      UInt32(cmdKey | controlKey),
      hotKeyID,
      GetEventDispatcherTarget(),
      0,
      &hotKeyRef
    )
    if registerStatus != noErr {
      print("❌ Failed to register hotkey: \(registerStatus)")
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
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
    }
    if let hotKeyHandlerRef {
      RemoveEventHandler(hotKeyHandlerRef)
    }
    themeObserver?.cancel()
  }
}

private func fourCharCode(_ string: String) -> FourCharCode {
  string.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
}
