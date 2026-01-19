import Carbon
import Cocoa
import Foundation

/// Hotkey activation modes
enum HotkeyMode: String, CaseIterable, Codable {
    case optionSpace = "option_space"           // ⌥ + Space (default)
    case doubleTapRightOption = "double_right_option"  // Double-tap Right ⌥
    case doubleTapRightCommand = "double_right_command" // Double-tap Right ⌘
    case doubleTapFn = "double_fn"              // Double-tap Fn/🌐
    case custom = "custom"                       // Custom shortcut via KeyboardShortcuts

    var displayName: String {
        switch self {
        case .optionSpace:
            return "⌥ Space"
        case .doubleTapRightOption:
            return "2× Right ⌥"
        case .doubleTapRightCommand:
            return "2× Right ⌘"
        case .doubleTapFn:
            return "2× Fn/🌐"
        case .custom:
            return "Своя комбинация"
        }
    }

    var description: String {
        switch self {
        case .optionSpace:
            return "Option + Пробел"
        case .doubleTapRightOption:
            return "Двойное нажатие правого Option"
        case .doubleTapRightCommand:
            return "Двойное нажатие правого Command"
        case .doubleTapFn:
            return "Двойное нажатие Fn или Globe"
        case .custom:
            return "Настраиваемая комбинация клавиш"
        }
    }
}

/// Service for detecting special hotkey combinations
final class HotkeyService {
    static let shared = HotkeyService()

    var onHotkeyTriggered: (() -> Void)?
    var currentMode: HotkeyMode = .optionSpace {
        didSet {
            updateEventTap()
        }
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Double-tap detection
    private var lastModifierPressTime: Date?
    private var lastModifierReleaseTime: Date?
    private var isModifierPressed = false
    private let doubleTapInterval: TimeInterval = 0.4

    // Track which modifier we're monitoring
    private var monitoredModifier: CGEventFlags = []

    private init() {}

    deinit {
        stopMonitoring()
    }

    /// Start monitoring for the current hotkey mode
    func startMonitoring() {
        guard currentMode != .optionSpace && currentMode != .custom else {
            // These modes are handled by KeyboardShortcuts
            stopMonitoring()
            return
        }

        // Set the monitored modifier based on mode
        switch currentMode {
        case .doubleTapRightOption:
            monitoredModifier = .maskAlternate
        case .doubleTapRightCommand:
            monitoredModifier = .maskCommand
        case .doubleTapFn:
            monitoredModifier = .maskSecondaryFn
        default:
            return
        }

        createEventTap()
    }

    /// Stop monitoring
    func stopMonitoring() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }

    private func updateEventTap() {
        stopMonitoring()
        startMonitoring()
    }

    private func createEventTap() {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)

        // Create callback as a C function pointer
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passRetained(event) }
            let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
            service.handleEvent(type: type, event: event)
            return Unmanaged.passRetained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap = eventTap else {
            print("Failed to create event tap. Make sure Accessibility permissions are granted.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        guard type == .flagsChanged else { return }

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Check if it's the right modifier key
        let isRightKey: Bool
        switch currentMode {
        case .doubleTapRightOption:
            // Right Option keycode is 61
            isRightKey = keyCode == 61
        case .doubleTapRightCommand:
            // Right Command keycode is 54
            isRightKey = keyCode == 54
        case .doubleTapFn:
            // Fn key keycode is 63
            isRightKey = keyCode == 63
        default:
            return
        }

        guard isRightKey else { return }

        let isPressed = flags.contains(monitoredModifier)

        if isPressed && !isModifierPressed {
            // Key pressed
            isModifierPressed = true
            lastModifierPressTime = Date()
        } else if !isPressed && isModifierPressed {
            // Key released
            isModifierPressed = false
            let now = Date()

            // Check for double-tap
            if let lastRelease = lastModifierReleaseTime,
               now.timeIntervalSince(lastRelease) < doubleTapInterval {
                // Double-tap detected!
                DispatchQueue.main.async { [weak self] in
                    self?.onHotkeyTriggered?()
                }
                lastModifierReleaseTime = nil
            } else {
                lastModifierReleaseTime = now
            }
        }
    }
}
