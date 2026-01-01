import SwiftUI
import AppKit

@main
struct MoonlightRemapperApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: iconName)
        }
        .menuBarExtraStyle(.window)
    }

    private var iconName: String {
        if appState.isEnabled && appState.isMoonlightFrontmost {
            return "keyboard.fill"  // Active remapping
        } else if appState.isEnabled {
            return "keyboard"       // Enabled but Moonlight not frontmost
        } else {
            return "keyboard.badge.ellipsis"  // Disabled
        }
    }
}

/// Central app state management
final class AppState: ObservableObject {
    static let shared = AppState()

    /// Moonlight bundle identifier
    static let moonlightBundleId = "com.moonlight-stream.Moonlight"

    // Persisted setting - whether remapping feature is enabled
    @AppStorage("isEnabled") var isEnabled: Bool = false {
        didSet {
            updateRemappingState()
        }
    }

    // Published state for UI updates
    @Published var hasAccessibilityPermission: Bool = false
    @Published var isMoonlightFrontmost: Bool = false

    // Core components
    private let frontmostAppMonitor = FrontmostAppMonitor()
    private let keyRemapEventTap = KeyRemapEventTap()
    private var pollTimer: Timer?

    private init() {
        checkAccessibilityPermission()
        setupFrontmostAppMonitor()

        // Check current frontmost app
        if let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier {
            isMoonlightFrontmost = frontmost == Self.moonlightBundleId
        }

        // Start event tap if enabled from previous session
        if isEnabled && hasAccessibilityPermission {
            _ = keyRemapEventTap.start()
            keyRemapEventTap.setRemappingActive(isMoonlightFrontmost)
        }
    }

    private func setupFrontmostAppMonitor() {
        // Callback when frontmost app changes
        frontmostAppMonitor.onFrontmostAppChanged = { [weak self] bundleId in
            guard let self = self else { return }
            self.handleFrontmostAppChange(bundleId)
        }

        // Start monitoring immediately
        frontmostAppMonitor.start()

        // Also poll periodically as fallback (fullscreen apps may not trigger notifications)
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
            let isMoonlight = bundleId == Self.moonlightBundleId

            // Only update if state changed
            if isMoonlight != self.isMoonlightFrontmost {
                self.handleFrontmostAppChange(bundleId)
            }
        }
    }

    private func handleFrontmostAppChange(_ bundleId: String?) {
        // Check if Moonlight is now frontmost
        let isMoonlight = bundleId == Self.moonlightBundleId

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isMoonlightFrontmost = isMoonlight

            // Re-check permission in case it was granted
            self.checkAccessibilityPermission()

            let shouldActivate = isMoonlight && self.isEnabled && self.hasAccessibilityPermission

            // Ensure event tap is started if we have permission
            if shouldActivate {
                _ = self.keyRemapEventTap.start()
            }
            self.keyRemapEventTap.setRemappingActive(shouldActivate)
        }
    }

    func checkAccessibilityPermission() {
        hasAccessibilityPermission = PermissionManager.checkAccessibility()
    }

    func requestAccessibilityPermission() {
        PermissionManager.requestAccessibility()

        // Check again after delay (user may grant permission)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.checkAccessibilityPermission()
            // Try to start if permission was granted
            if self?.hasAccessibilityPermission == true && self?.isEnabled == true {
                _ = self?.keyRemapEventTap.start()
                self?.keyRemapEventTap.setRemappingActive(self?.isMoonlightFrontmost ?? false)
            }
        }
    }

    private func updateRemappingState() {
        if isEnabled {
            guard hasAccessibilityPermission else {
                requestAccessibilityPermission()
                return
            }
            _ = keyRemapEventTap.start()
            keyRemapEventTap.setRemappingActive(isMoonlightFrontmost)
        } else {
            keyRemapEventTap.setRemappingActive(false)
        }
    }
}
