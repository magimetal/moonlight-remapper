import Foundation
import ApplicationServices
import AppKit

/// Manages Accessibility permission checking and requesting
struct PermissionManager {

    /// Check if the app has Accessibility permission
    static func checkAccessibility() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Request Accessibility permission (opens System Settings with prompt)
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Open Accessibility settings directly
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
