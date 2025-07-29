import AppKit
import ApplicationServices
import Foundation
import ServiceManagement

@MainActor
class AppState: ObservableObject {
    @Published var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }

    @Published var launchAtLoginError: String?
    @Published var showingLaunchAtLoginAlert = false
    @Published var hasAccessibilityPermission = false
    @Published var showingAccessibilityAlert = false

    private nonisolated(unsafe) var permissionCheckTimer: Timer?

    // Track if user has seen the accessibility dialog
    private let hasSeenAccessibilityDialogKey = "hasSeenAccessibilityDialog"

    init() {
        // Initialize launch at login state
        // checkLaunchAtLoginStatus()

        // Check accessibility permissions on startup
        _ = checkAccessibilityPermissions()

        // Start periodic permission checking
        startPeriodicPermissionChecking()
    }

    private func checkLaunchAtLoginStatus() {
        // Check current launch at login status using SMAppService
        Task {
            let status = SMAppService.mainApp.status
            launchAtLogin = (status == .enabled)
        }
    }

    private func updateLaunchAtLogin() {
        Task {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                    launchAtLoginError = nil
                } else {
                    try SMAppService.mainApp.unregister()
                    launchAtLoginError = nil
                }
            } catch let error as NSError {
                // Handle specific SMAppService errors
                launchAtLogin = !launchAtLogin  // Revert the toggle

                if error.domain == "SMAppServiceErrorDomain" && error.code == 22 {
                    launchAtLoginError =
                        "Launch at login is not available in development builds. Please use a properly signed app bundle."
                } else {
                    launchAtLoginError =
                        "Failed to update launch at login: \(error.localizedDescription)"
                }

                showingLaunchAtLoginAlert = true
            }
        }
    }

    func checkAccessibilityPermissions() -> Bool {
        let accessEnabled = AXIsProcessTrusted()
        hasAccessibilityPermission = accessEnabled
        return accessEnabled
    }

    func requestAccessibilityPermissions() {
        // Simply prompt for accessibility permissions without options first
        let accessEnabled = AXIsProcessTrusted()
        hasAccessibilityPermission = accessEnabled

        if !accessEnabled {
            // Open system preferences directly
            openAccessibilitySettings()
        }
    }

    func openAccessibilitySettings() {
        let url = URL(
            string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func shouldShowAccessibilityDialogOnLaunch() -> Bool {
        // Show if haven't seen it and don't have permissions
        return !hasSeenAccessibilityDialog() && !hasAccessibilityPermission
    }

    func markAccessibilityDialogAsSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenAccessibilityDialogKey)
    }

    private func hasSeenAccessibilityDialog() -> Bool {
        return UserDefaults.standard.bool(forKey: hasSeenAccessibilityDialogKey)
    }

    private func startPeriodicPermissionChecking() {
        // Check every 2 seconds to catch when user grants permission
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                _ = self?.checkAccessibilityPermissions()
            }
        }
    }

    deinit {
        permissionCheckTimer?.invalidate()
    }
}
