import AppKit
import Foundation

/// Service for copying text to clipboard and optionally auto-pasting
final class PasteService {
    static let shared = PasteService()

    private let pasteboard = NSPasteboard.general

    /// Transient pasteboard type - tells clipboard managers this is temporary data
    private let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    /// Source identifier type
    private let sourceType = NSPasteboard.PasteboardType("org.nspasteboard.source")

    // MARK: - Public Methods

    /// Copy text to clipboard (permanent)
    func copyToClipboard(_ text: String) {
        setClipboard(text, transient: false)
    }

    /// Set clipboard content with optional transient flag
    /// - Parameters:
    ///   - text: Text to copy
    ///   - transient: If true, marks as temporary (for clipboard managers)
    @discardableResult
    func setClipboard(_ text: String, transient: Bool = false) -> Bool {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Add source identifier
        if let bundleId = Bundle.main.bundleIdentifier {
            pasteboard.setString(bundleId, forType: sourceType)
        }

        // Mark as transient if requested (tells clipboard managers to ignore)
        if transient {
            pasteboard.setData(Data(), forType: transientType)
        }

        return true
    }

    /// Paste text at cursor with optional clipboard restoration
    /// - Parameters:
    ///   - text: Text to paste
    ///   - restoreClipboard: If true, restores previous clipboard content after paste
    func pasteAtCursor(_ text: String, restoreClipboard: Bool = true) {
        // Save current clipboard contents if we need to restore
        var savedContents: [(NSPasteboard.PasteboardType, Data)] = []

        if restoreClipboard {
            let currentItems = pasteboard.pasteboardItems ?? []
            for item in currentItems {
                for type in item.types {
                    if let data = item.data(forType: type) {
                        savedContents.append((type, data))
                    }
                }
            }
        }

        // Set clipboard with transient flag
        setClipboard(text, transient: restoreClipboard)

        // Paste after small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.simulatePaste()
        }

        // Restore clipboard after 1 second
        if restoreClipboard && !savedContents.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.pasteboard.clearContents()
                for (type, data) in savedContents {
                    self.pasteboard.setData(data, forType: type)
                }
                print("[PasteService] Clipboard restored")
            }
        }
    }

    /// Check if we have accessibility permissions
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Check with optional prompt
    func checkAccessibilityPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Request accessibility permission (shows system dialog)
    func requestAccessibilityPermission() {
        _ = checkAccessibilityPermission(prompt: true)
    }

    /// Open System Settings at Privacy & Security > Accessibility
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Paste Methods

    /// Simulate Cmd+V key press
    func simulatePaste() {
        print("[PasteService] 🔵 simulatePaste() called")

        // Detailed accessibility check
        let trusted = AXIsProcessTrusted()
        print("[PasteService] AXIsProcessTrusted() = \(trusted)")

        guard trusted else {
            print("[PasteService] ❌ Cannot paste: no accessibility permission")
            print("[PasteService] Opening System Preferences...")
            openAccessibilitySettings()
            return
        }

        let frontApp = NSWorkspace.shared.frontmostApplication
        let bundleId = frontApp?.bundleIdentifier ?? "unknown"
        print("[PasteService] ✅ Pasting to app: \(frontApp?.localizedName ?? "unknown") (\(bundleId))")

        // Note: Removed frontmost app check - the floating window uses .nonactivating
        // so focus should already be on the target app. If we're still frontmost,
        // CGEvent will send the paste to wherever the keyboard focus actually is.

        // Try CGEvent first (VoiceInk style with 4 separate events)
        if simulatePasteWithCGEvent() {
            print("[PasteService] Paste sent via CGEvent")
            return
        }

        // Fallback to AppleScript
        print("[PasteService] CGEvent failed, trying AppleScript")
        if simulatePasteWithAppleScript() {
            print("[PasteService] Paste sent via AppleScript")
            return
        }

        print("[PasteService] All paste methods failed")
    }

    /// CGEvent paste - Maccy style with combinedSessionState and cgSessionEventTap
    private func simulatePasteWithCGEvent() -> Bool {
        print("[PasteService] ⚡ simulatePasteWithCGEvent called")
        // Use combinedSessionState (как Maccy) - объединяет состояние от всех источников
        let source = CGEventSource(stateID: .combinedSessionState)

        // Фильтруем локальные события во время симуляции вставки
        source?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        let vKeyCode: CGKeyCode = 0x09  // V key

        // Создаём события V down и V up
        guard let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            print("[PasteService] Failed to create CGEvents")
            return false
        }

        // Флаг Command + 0x000008 (как в Maccy для NX_DEVICELCMDKEYMASK)
        let cmdFlag = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x000008)
        keyVDown.flags = cmdFlag
        keyVUp.flags = cmdFlag

        // Постим в cgSessionEventTap (как Maccy, не cgAnnotatedSessionEventTap!)
        keyVDown.post(tap: .cgSessionEventTap)
        keyVUp.post(tap: .cgSessionEventTap)

        return true
    }

    /// AppleScript fallback
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

    // MARK: - Additional Key Simulation

    /// Simulate pressing Enter/Return key
    func pressEnter() {
        guard hasAccessibilityPermission() else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        let enterKeyCode: CGKeyCode = 0x24  // Return key

        guard let enterDown = CGEvent(keyboardEventSource: source, virtualKey: enterKeyCode, keyDown: true),
              let enterUp = CGEvent(keyboardEventSource: source, virtualKey: enterKeyCode, keyDown: false) else {
            return
        }

        enterDown.post(tap: .cghidEventTap)
        enterUp.post(tap: .cghidEventTap)
    }

    /// Simulate pressing Tab key
    func pressTab() {
        guard hasAccessibilityPermission() else { return }

        let source = CGEventSource(stateID: .hidSystemState)
        let tabKeyCode: CGKeyCode = 0x30  // Tab key

        guard let tabDown = CGEvent(keyboardEventSource: source, virtualKey: tabKeyCode, keyDown: true),
              let tabUp = CGEvent(keyboardEventSource: source, virtualKey: tabKeyCode, keyDown: false) else {
            return
        }

        tabDown.post(tap: .cghidEventTap)
        tabUp.post(tap: .cghidEventTap)
    }
}
