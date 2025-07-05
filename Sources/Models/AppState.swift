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

    init() {
        // Initialize launch at login state
        // checkLaunchAtLoginStatus()
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
}
