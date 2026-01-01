import Foundation
import CoreGraphics
import Carbon.HIToolbox

/// Intercepts keyboard events and remaps Left CMD to Left CTRL
/// Only active when Moonlight is the frontmost application
final class KeyRemapEventTap {

    // Key codes (macOS virtual key codes)
    static let leftCommandKeyCode: CGKeyCode = 55  // kVK_Command
    static let leftControlKeyCode: CGKeyCode = 59  // kVK_Control

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Whether remapping is currently active (Moonlight is frontmost AND feature enabled)
    private var isRemappingActive: Bool = false
    private let stateLock = NSLock()

    /// Track if Left CMD was remapped on press (to correctly handle release)
    private var leftCmdRemapped: Bool = false

    /// Set whether remapping should be active
    func setRemappingActive(_ active: Bool) {
        stateLock.lock()
        let wasActive = isRemappingActive
        isRemappingActive = active
        stateLock.unlock()

        if wasActive != active {
            NSLog("[KeyRemapEventTap] Remapping \(active ? "ACTIVATED" : "DEACTIVATED")")
        }
    }

    /// Start the event tap
    func start() -> Bool {
        guard eventTap == nil else { return true }

        // Listen for flagsChanged events (modifier keys)
        let eventMask: CGEventMask = 1 << CGEventType.flagsChanged.rawValue

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let tap = Unmanaged<KeyRemapEventTap>.fromOpaque(refcon).takeUnretainedValue()
                return tap.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[KeyRemapEventTap] Failed to create event tap - Accessibility permission required")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        NSLog("[KeyRemapEventTap] Event tap started")
        return true
    }

    /// Stop the event tap
    func stop() {
        guard let tap = eventTap else { return }

        CGEvent.tapEnable(tap: tap, enable: false)

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }

        eventTap = nil
        NSLog("[KeyRemapEventTap] Event tap stopped")
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled by system
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // Only process flagsChanged events
        guard type == .flagsChanged else {
            return Unmanaged.passRetained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Check if this is Left Command key
        guard keyCode == Self.leftCommandKeyCode else {
            return Unmanaged.passRetained(event)
        }

        // Determine if key is being pressed or released
        let isKeyDown = flags.contains(.maskCommand)

        stateLock.lock()
        let shouldRemap = isRemappingActive
        stateLock.unlock()

        // Decide whether to remap
        let performRemap: Bool
        if isKeyDown {
            // Key press: remap if active
            performRemap = shouldRemap
            leftCmdRemapped = shouldRemap
        } else {
            // Key release: remap if we remapped the press
            performRemap = leftCmdRemapped
            leftCmdRemapped = false
        }

        if performRemap {
            // Remap Left CMD to Left CTRL
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(Self.leftControlKeyCode))

            // Update modifier flags: remove command, add control
            // Use raw flag manipulation to set LEFT control specifically
            // Left Control device flag is 0x0001, maskControl is 0x40000
            var rawFlags = flags.rawValue

            // Remove command flags (mask 0x100000 and device flag 0x08 for left cmd)
            rawFlags &= ~UInt64(0x100008)

            if isKeyDown {
                // Add left control: maskControl (0x40000) + left control device flag (0x0001)
                rawFlags |= UInt64(0x40001)
            } else {
                // Remove control flags
                rawFlags &= ~UInt64(0x42001)  // Remove maskControl and both device flags
            }

            event.flags = CGEventFlags(rawValue: rawFlags)
        }

        return Unmanaged.passRetained(event)
    }

    deinit {
        stop()
    }
}
