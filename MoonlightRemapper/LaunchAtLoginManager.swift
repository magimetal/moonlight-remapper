import Foundation
import ServiceManagement

/// Manages launch at login functionality using SMAppService
struct LaunchAtLoginManager {

    /// Check if app is registered to launch at login
    static var isEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }

    /// Enable or disable launch at login
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                NSLog("[LaunchAtLogin] Registered for launch at login")
            } else {
                try SMAppService.mainApp.unregister()
                NSLog("[LaunchAtLogin] Unregistered from launch at login")
            }
        } catch {
            NSLog("[LaunchAtLogin] Failed to update launch at login: \(error)")
        }
    }
}
