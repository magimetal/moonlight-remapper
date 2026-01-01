import Foundation
import AppKit

/// Monitors which application is currently frontmost (active)
final class FrontmostAppMonitor {

    /// Callback when frontmost app changes - provides bundle identifier
    var onFrontmostAppChanged: ((String?) -> Void)?

    private var observer: NSObjectProtocol?

    /// Start monitoring frontmost app changes
    func start() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: NSWorkspace.shared,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            let bundleId = app.bundleIdentifier
            NSLog("[FrontmostAppMonitor] App activated: \(bundleId ?? "unknown")")
            self?.onFrontmostAppChanged?(bundleId)
        }

        NSLog("[FrontmostAppMonitor] Started monitoring")
    }

    /// Stop monitoring frontmost app changes
    func stop() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
            NSLog("[FrontmostAppMonitor] Stopped monitoring")
        }
    }

    /// Get the current frontmost application bundle identifier
    static var currentFrontmostBundleId: String? {
        return NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    deinit {
        stop()
    }
}
