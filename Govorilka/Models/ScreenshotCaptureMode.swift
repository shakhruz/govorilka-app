import AppKit
import CoreGraphics

/// Capture mode for screenshots: specific window or entire display
enum ScreenshotCaptureMode: Equatable, Identifiable {
    case window
    case display(CGDirectDisplayID)

    var id: String {
        switch self {
        case .window:
            return "window"
        case .display(let displayID):
            return "display_\(displayID)"
        }
    }
}

// MARK: - Display name helpers

extension Array where Element == ScreenshotCaptureMode {
    /// Returns a human-readable name for the given mode within the context of this list.
    /// If there is only one display, it shows "Окно" / "Экран".
    /// If there are multiple displays, it numbers them: "Дисплей 1", "Дисплей 2".
    func displayName(for mode: ScreenshotCaptureMode) -> String {
        switch mode {
        case .window:
            return "Окно"
        case .display:
            let displays = self.filter {
                if case .display = $0 { return true }
                return false
            }
            if displays.count <= 1 {
                return "Экран"
            }
            if let idx = displays.firstIndex(of: mode) {
                return "Дисплей \(idx + 1)"
            }
            return "Экран"
        }
    }
}

// MARK: - NSScreen extension

extension NSScreen {
    /// The CGDirectDisplayID for this screen, extracted from deviceDescription.
    var displayID: CGDirectDisplayID {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return CGMainDisplayID()
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }
}
