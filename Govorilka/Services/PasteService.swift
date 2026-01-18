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

    // MARK: - Private Methods

    /// Simulate Cmd+V key press using CGEvent
    private func simulatePaste() {
        // Cmd key
        let cmdKey = CGEventFlags.maskCommand

        // 'v' key code
        let vKeyCode: CGKeyCode = 0x09

        // Create key down event
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) else {
            print("Failed to create key down event")
            return
        }
        keyDownEvent.flags = cmdKey

        // Create key up event
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else {
            print("Failed to create key up event")
            return
        }
        keyUpEvent.flags = cmdKey

        // Post events
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
}
