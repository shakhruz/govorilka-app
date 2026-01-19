import AppKit
import Foundation

/// Service for copying text to clipboard and optionally auto-pasting
final class PasteService {
    static let shared = PasteService()

    private let pasteboard = NSPasteboard.general

    // MARK: - Public Methods

    /// Copy text to clipboard
    func copyToClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Copy text and simulate Cmd+V paste
    func copyAndPaste(_ text: String) {
        copyToClipboard(text)

        // Small delay to ensure clipboard is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    /// Check if we have accessibility permissions
    func hasAccessibilityPermission() -> Bool {
        // Check if the process is trusted for accessibility
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Request accessibility permission (shows system dialog)
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Open System Settings at Privacy & Security > Accessibility
    func openAccessibilitySettings() {
        // macOS 13+ uses new System Settings URL scheme
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Public Methods (continued)

    /// Simulate Cmd+V key press using CGEvent
    func simulatePaste() {
        // Double-check we have permission
        guard hasAccessibilityPermission() else {
            print("[PasteService] Cannot paste: no accessibility permission")
            return
        }

        // Get the frontmost app (should be the target app, not us)
        let frontApp = NSWorkspace.shared.frontmostApplication
        print("[PasteService] Pasting to app: \(frontApp?.localizedName ?? "unknown")")

        // Skip if somehow we're the frontmost app
        if frontApp?.bundleIdentifier == Bundle.main.bundleIdentifier {
            print("[PasteService] Skipping paste - we are the frontmost app")
            return
        }

        // Try CGEvent first
        if simulatePasteWithCGEvent() {
            print("[PasteService] Paste command sent via CGEvent")
            return
        }

        // Fallback to AppleScript if CGEvent fails
        print("[PasteService] CGEvent failed, trying AppleScript fallback")
        if simulatePasteWithAppleScript() {
            print("[PasteService] Paste command sent via AppleScript")
            return
        }

        print("[PasteService] All paste methods failed")
    }

    /// Try to paste using CGEvent (primary method)
    private func simulatePasteWithCGEvent() -> Bool {
        // Cmd key
        let cmdKey = CGEventFlags.maskCommand

        // 'v' key code
        let vKeyCode: CGKeyCode = 0x09

        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) else {
            print("[PasteService] Failed to create key down event")
            return false
        }
        keyDownEvent.flags = cmdKey

        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else {
            print("[PasteService] Failed to create key up event")
            return false
        }
        keyUpEvent.flags = cmdKey

        // Post events to the system
        keyDownEvent.post(tap: .cghidEventTap)

        // Small delay between key down and up for reliability
        usleep(10000) // 10ms

        keyUpEvent.post(tap: .cghidEventTap)

        return true
    }

    /// Fallback: paste using AppleScript
    private func simulatePasteWithAppleScript() -> Bool {
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """

        guard let appleScript = NSAppleScript(source: script) else {
            print("[PasteService] Failed to create AppleScript")
            return false
        }

        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)

        if let error = error {
            print("[PasteService] AppleScript error: \(error)")
            return false
        }

        return true
    }
}
