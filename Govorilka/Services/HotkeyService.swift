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
            return "⌥ Space или правый Option"
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
    var onEscapePressed: (() -> Void)?
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

    // Single-tap right Option detection (for optionSpace mode)
    private var rightOptionPressTime: Date?
    private let singleTapMaxDuration: TimeInterval = 0.3

    // Флаг: была ли нажата другая клавиша пока Option зажат
    // Если да - это комбинация (Option+что-то), а не single-tap Option
    private var otherKeyPressedDuringOption = false

    // Track which modifier we're monitoring
    private var monitoredModifier: CGEventFlags = []

    private init() {}

    deinit {
        stopMonitoring()
    }

    /// Start monitoring for the current hotkey mode
    func startMonitoring() {
        guard currentMode != .custom else {
            // Custom mode is handled by KeyboardShortcuts only
            stopMonitoring()
            return
        }

        // Set the monitored modifier based on mode
        switch currentMode {
        case .optionSpace:
            // Also monitor for single-tap right Option
            monitoredModifier = .maskAlternate
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
        let eventMask = (1 << CGEventType.flagsChanged.rawValue) | (1 << CGEventType.keyDown.rawValue)

        // Create callback as a C function pointer
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue()
            service.handleEvent(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap = eventTap else {
            print("[HotkeyService] Failed to create event tap. Check Accessibility permissions.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        // Обработка keyDown событий
        if type == .keyDown {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            // ESC для отмены записи (keyCode 53)
            if keyCode == 53 {
                DispatchQueue.main.async { [weak self] in
                    self?.onEscapePressed?()
                }
            }

            // Если правый Option зажат и нажата другая клавиша — это комбинация, не single-tap
            if rightOptionPressTime != nil {
                otherKeyPressedDuringOption = true
            }
            return
        }

        guard type == .flagsChanged else { return }

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Handle single-tap right Option for optionSpace mode
        if currentMode == .optionSpace {
            // Right Option keycode is 61
            guard keyCode == 61 else { return }

            let isPressed = flags.contains(.maskAlternate)

            if isPressed {
                // Начало нажатия правого Option
                rightOptionPressTime = Date()
                otherKeyPressedDuringOption = false
            } else if let pressTime = rightOptionPressTime {
                // Отпускание правого Option
                let duration = Date().timeIntervalSince(pressTime)
                let wasOtherKeyPressed = otherKeyPressedDuringOption

                // Сбрасываем состояние
                rightOptionPressTime = nil
                otherKeyPressedDuringOption = false

                // Не срабатывать если была нажата другая клавиша (например, Space)
                // В этом случае это Option+Space, который обрабатывает KeyboardShortcuts
                if wasOtherKeyPressed {
                    return
                }

                // Срабатывать только если это было короткое нажатие (< 0.3 сек)
                if duration < singleTapMaxDuration {
                    DispatchQueue.main.async { [weak self] in
                        self?.onHotkeyTriggered?()
                    }
                }
            }
            return
        }

        // Check if it's the right modifier key (for double-tap modes)
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
