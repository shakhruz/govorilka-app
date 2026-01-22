import Carbon
import Cocoa
import Foundation

/// Hotkey activation modes
enum HotkeyMode: String, CaseIterable, Codable {
    case optionSpace = "option_space"           // ⌥ + Space (KeyboardShortcuts only)
    case rightCommand = "right_command"          // Single-tap Right ⌘ (recommended)
    case doubleTapRightOption = "double_right_option"  // Double-tap Right ⌥

    var displayName: String {
        switch self {
        case .optionSpace:
            return "⌥ Space"
        case .rightCommand:
            return "Right ⌘"
        case .doubleTapRightOption:
            return "2× Right ⌥"
        }
    }

    var description: String {
        switch self {
        case .optionSpace:
            return "Option + Пробел"
        case .rightCommand:
            return "Правый Command (рекомендуется)"
        case .doubleTapRightOption:
            return "Двойное нажатие правого Option"
        }
    }

    /// Whether this mode needs NSEvent monitoring
    var needsEventMonitoring: Bool {
        switch self {
        case .optionSpace:
            return false  // Handled by KeyboardShortcuts only
        case .rightCommand, .doubleTapRightOption:
            return true   // Needs our custom monitoring
        }
    }
}

/// Service for detecting special hotkey combinations using NSEvent monitors
/// Inspired by VoiceInk's approach for reliable key detection
final class HotkeyService {
    static let shared = HotkeyService()

    /// Callback for normal voice input
    var onHotkeyTriggered: (() -> Void)?

    /// Callback for Pro mode screenshot + feedback (Option+Space in Pro mode)
    var onProHotkeyTriggered: (() -> Void)?

    /// Callback for ESC to cancel
    var onEscapePressed: (() -> Void)?

    /// Current hotkey mode (used when Pro mode is disabled)
    var currentMode: HotkeyMode = .optionSpace {
        didSet {
            if oldValue != currentMode {
                restartMonitoring()
            }
        }
    }

    /// Pro mode: Right ⌘ = voice, Option+Space = screenshot
    var proModeEnabled: Bool = false {
        didSet {
            if oldValue != proModeEnabled {
                restartMonitoring()
            }
        }
    }

    // NSEvent monitors
    private var localMonitor: Any?
    private var globalMonitor: Any?

    // Separate ESC monitor (always active)
    private var escLocalMonitor: Any?
    private var escGlobalMonitor: Any?

    // Key state tracking (using event.timestamp for accuracy)
    private var isKeyPressed = false
    private var lastKeyPressTimestamp: TimeInterval = 0
    private var lastKeyReleaseTimestamp: TimeInterval = 0

    // Double-tap detection
    private let doubleTapInterval: TimeInterval = 0.4

    // Keycodes
    private let rightCommandKeyCode: UInt16 = 54
    private let rightOptionKeyCode: UInt16 = 61
    private let escapeKeyCode: UInt16 = 53

    private init() {}

    deinit {
        stopMonitoring()
    }

    /// Start monitoring for the current hotkey mode
    func startMonitoring() {
        // Always monitor ESC for cancel functionality
        setupEscapeMonitor()

        if proModeEnabled {
            // Pro mode: always monitor Right Command for voice input
            setupEventMonitors()
            return
        }

        guard currentMode.needsEventMonitoring else {
            // optionSpace mode is handled by KeyboardShortcuts only
            // But we still need ESC monitoring (done above)
            stopHotkeyMonitoring()
            return
        }

        setupEventMonitors()
    }

    /// Stop all monitoring
    func stopMonitoring() {
        stopHotkeyMonitoring()
        stopEscapeMonitoring()
    }

    /// Stop hotkey monitoring (but not ESC)
    private func stopHotkeyMonitoring() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }

        // Reset state
        isKeyPressed = false
        lastKeyPressTimestamp = 0
        lastKeyReleaseTimestamp = 0
    }

    /// Stop ESC monitoring
    private func stopEscapeMonitoring() {
        if let monitor = escLocalMonitor {
            NSEvent.removeMonitor(monitor)
            escLocalMonitor = nil
        }
        if let monitor = escGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            escGlobalMonitor = nil
        }
    }

    /// Setup ESC key monitoring (always active)
    private func setupEscapeMonitor() {
        // Don't setup if already active
        guard escLocalMonitor == nil else { return }

        let eventMask: NSEvent.EventTypeMask = [.keyDown]

        // Global monitor for when app is not focused
        escGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEscapeEvent(event)
        }

        // Local monitor for when app is focused
        escLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEscapeEvent(event)
            return event
        }
    }

    /// Handle ESC key event
    private func handleEscapeEvent(_ event: NSEvent) {
        guard event.keyCode == escapeKeyCode else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onEscapePressed?()
        }
    }

    private func restartMonitoring() {
        stopMonitoring()
        startMonitoring()
    }

    private func setupEventMonitors() {
        // Don't setup if already active
        guard localMonitor == nil else { return }

        // Only flagsChanged for modifier keys (ESC handled separately)
        let eventMask: NSEvent.EventTypeMask = [.flagsChanged]

        // Global monitor for when app is not focused
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEvent(event)
        }

        // Local monitor for when app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    private func handleEvent(_ event: NSEvent) {
        // Only process flags changed events for modifier keys
        // ESC is handled by separate monitor (setupEscapeMonitor)
        guard event.type == .flagsChanged else { return }

        if proModeEnabled {
            // Pro mode: Right ⌘ for voice, Option+Space handled by KeyboardShortcuts
            handleRightCommandForVoice(event)
        } else {
            // Normal mode: use selected hotkey
            switch currentMode {
            case .rightCommand:
                handleRightCommandMode(event)
            case .doubleTapRightOption:
                handleDoubleTapRightOptionMode(event)
            case .optionSpace:
                // This mode doesn't use event monitoring
                break
            }
        }
    }

    // MARK: - Pro Mode: Right Command for Voice Input

    private func handleRightCommandForVoice(_ event: NSEvent) {
        guard event.keyCode == rightCommandKeyCode else { return }

        let currentKeyState = event.modifierFlags.contains(.command)

        // State guard: only process actual state changes
        guard isKeyPressed != currentKeyState else { return }

        if currentKeyState {
            // Key pressed
            isKeyPressed = true
            lastKeyPressTimestamp = event.timestamp
        } else {
            // Key released
            isKeyPressed = false

            // Check if it was a quick tap (not held down)
            let pressDuration = event.timestamp - lastKeyPressTimestamp
            if pressDuration < 0.3 {
                triggerNormalHotkey()
            }
        }
    }

    // MARK: - Right Command Mode (Single-tap)

    private func handleRightCommandMode(_ event: NSEvent) {
        guard event.keyCode == rightCommandKeyCode else { return }

        let currentKeyState = event.modifierFlags.contains(.command)

        // State guard: only process actual state changes
        guard isKeyPressed != currentKeyState else { return }

        if currentKeyState {
            // Key pressed
            isKeyPressed = true
            lastKeyPressTimestamp = event.timestamp
        } else {
            // Key released
            isKeyPressed = false

            // Check if it was a quick tap (not held down)
            let pressDuration = event.timestamp - lastKeyPressTimestamp
            if pressDuration < 0.3 {
                triggerNormalHotkey()
            }
        }
    }

    // MARK: - Double-tap Right Option Mode

    private func handleDoubleTapRightOptionMode(_ event: NSEvent) {
        guard event.keyCode == rightOptionKeyCode else { return }

        let currentKeyState = event.modifierFlags.contains(.option)

        // State guard: only process actual state changes
        guard isKeyPressed != currentKeyState else { return }

        if currentKeyState {
            // Key pressed
            isKeyPressed = true
            lastKeyPressTimestamp = event.timestamp
        } else {
            // Key released
            isKeyPressed = false
            let now = event.timestamp

            // Check for double-tap
            if lastKeyReleaseTimestamp > 0 &&
               (now - lastKeyReleaseTimestamp) < doubleTapInterval {
                // Double-tap detected
                lastKeyReleaseTimestamp = 0
                triggerNormalHotkey()
            } else {
                lastKeyReleaseTimestamp = now
            }
        }
    }

    // MARK: - Triggers

    private func triggerNormalHotkey() {
        DispatchQueue.main.async { [weak self] in
            self?.onHotkeyTriggered?()
        }
    }

    private func triggerProHotkey() {
        DispatchQueue.main.async { [weak self] in
            self?.onProHotkeyTriggered?()
        }
    }
}
