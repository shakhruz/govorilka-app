import AppKit
import Foundation

/// Service for capturing and managing screenshots in Pro mode
final class ScreenshotService {
    static let shared = ScreenshotService()

    /// Screenshots directory in Application Support
    private var screenshotsDirectory: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("[ScreenshotService] Failed to get Application Support directory")
            return nil
        }

        let govorilkaDir = appSupport.appendingPathComponent("Govorilka", isDirectory: true)
        let screenshotsDir = govorilkaDir.appendingPathComponent("Screenshots", isDirectory: true)

        // Create directory if needed
        do {
            try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        } catch {
            print("[ScreenshotService] Failed to create screenshots directory: \(error)")
            return nil
        }

        return screenshotsDir
    }

    // MARK: - Public Methods

    /// Capture the entire screen (primary display, backward compatibility)
    /// - Returns: NSImage of the screen, or nil if capture failed
    func captureScreen() async -> NSImage? {
        return captureDisplay(CGMainDisplayID())
    }

    /// List available capture modes: .window + one .display per active display
    func availableCaptureModes() -> [ScreenshotCaptureMode] {
        var modes: [ScreenshotCaptureMode] = [.window]

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        let result = CGGetActiveDisplayList(UInt32(displayIDs.count), &displayIDs, &displayCount)

        if result == .success && displayCount > 0 {
            for i in 0..<Int(displayCount) {
                modes.append(.display(displayIDs[i]))
            }
        } else {
            // Fallback: at least the main display
            modes.append(.display(CGMainDisplayID()))
        }

        return modes
    }

    /// Capture a specific display by its ID
    /// - Parameter displayID: The CGDirectDisplayID to capture
    /// - Returns: NSImage or nil if capture failed
    func captureDisplay(_ displayID: CGDirectDisplayID) -> NSImage? {
        guard let cgImage = CGDisplayCreateImage(displayID) else {
            print("[ScreenshotService] Failed to capture display \(displayID)")
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(cgImage: cgImage, size: size)
        print("[ScreenshotService] Display \(displayID) captured: \(Int(size.width))x\(Int(size.height))")
        return image
    }

    /// Capture the frontmost window (excluding Govorilka itself)
    /// - Returns: NSImage of the window, or nil if no suitable window found
    func captureFrontmostWindow() -> NSImage? {
        // Get the list of on-screen windows
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            print("[ScreenshotService] Failed to get window list")
            return nil
        }

        let myPID = Int32(ProcessInfo.processInfo.processIdentifier)
        // Try to find the frontmost window of the previously active app
        let targetPID = findPreviousFrontmostAppPID() ?? myPID

        // Find the topmost window that belongs to a non-Govorilka app
        var bestWindow: (id: CGWindowID, bounds: CGRect)?

        for windowInfo in windowList {
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = windowInfo[kCGWindowLayer as String] as? Int else {
                continue
            }

            // Skip our own windows and non-normal-layer windows
            guard ownerPID != myPID, layer == 0 else { continue }

            let bounds = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )

            // Skip tiny windows (toolbars, status items, etc.)
            guard bounds.width > 50 && bounds.height > 50 else { continue }

            // Prefer windows from the target (previously frontmost) app
            if ownerPID == targetPID {
                bestWindow = (id: windowID, bounds: bounds)
                break
            }

            // Otherwise take the first suitable window (highest in z-order)
            if bestWindow == nil {
                bestWindow = (id: windowID, bounds: bounds)
            }
        }

        guard let target = bestWindow else {
            print("[ScreenshotService] No suitable frontmost window found")
            return nil
        }

        // Capture just that window
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            target.id,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            print("[ScreenshotService] Failed to capture window \(target.id)")
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(cgImage: cgImage, size: size)
        print("[ScreenshotService] Window captured: \(Int(size.width))x\(Int(size.height))")
        return image
    }

    /// Capture using the specified mode
    /// - Parameter mode: The capture mode (.window or .display)
    /// - Returns: NSImage or nil if capture failed
    func capture(mode: ScreenshotCaptureMode) -> NSImage? {
        switch mode {
        case .window:
            return captureFrontmostWindow()
        case .display(let displayID):
            return captureDisplay(displayID)
        }
    }

    /// Find the PID of the previously frontmost application (not Govorilka)
    private func findPreviousFrontmostAppPID() -> Int32? {
        let myBundleID = Bundle.main.bundleIdentifier
        // NSWorkspace.shared.runningApplications returns apps in activation order (most recent first)
        // The frontmost is first; we want the one just after Govorilka if Govorilka is frontmost
        let apps = NSWorkspace.shared.runningApplications
        let frontmost = NSWorkspace.shared.frontmostApplication

        if frontmost?.bundleIdentifier != myBundleID {
            // Another app is frontmost — use it
            return frontmost?.processIdentifier
        }

        // Govorilka is frontmost — find the next regular app
        for app in apps where app.activationPolicy == .regular
            && app.bundleIdentifier != myBundleID
            && !app.isTerminated {
            return app.processIdentifier
        }

        return nil
    }

    /// Save screenshot to the screenshots directory
    /// - Parameter image: The image to save
    /// - Returns: Filename (not full path) or nil if save failed
    func saveScreenshot(_ image: NSImage) -> String? {
        guard let directory = screenshotsDirectory else {
            print("[ScreenshotService] Screenshots directory unavailable")
            return nil
        }

        let filename = generateFilename()
        let fileURL = directory.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("[ScreenshotService] Failed to convert image to PNG")
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            print("[ScreenshotService] Screenshot saved: \(filename)")
            return filename
        } catch {
            print("[ScreenshotService] Failed to save screenshot: \(error)")
            return nil
        }
    }

    /// Load screenshot from the screenshots directory
    /// - Parameter filename: The filename (not full path)
    /// - Returns: NSImage or nil if load failed
    func loadScreenshot(filename: String) -> NSImage? {
        guard let directory = screenshotsDirectory else {
            print("[ScreenshotService] Screenshots directory unavailable")
            return nil
        }

        let fileURL = directory.appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[ScreenshotService] Screenshot not found: \(filename)")
            return nil
        }

        guard let image = NSImage(contentsOf: fileURL) else {
            print("[ScreenshotService] Failed to load screenshot: \(filename)")
            return nil
        }

        return image
    }

    /// Delete screenshot from the screenshots directory
    /// - Parameter filename: The filename (not full path)
    func deleteScreenshot(filename: String) {
        guard let directory = screenshotsDirectory else {
            print("[ScreenshotService] Screenshots directory unavailable")
            return
        }

        let fileURL = directory.appendingPathComponent(filename)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("[ScreenshotService] Screenshot deleted: \(filename)")
        } catch {
            print("[ScreenshotService] Failed to delete screenshot: \(error)")
        }
    }

    /// Export screenshot and text to a user-selected folder
    /// - Parameters:
    ///   - screenshot: The screenshot image
    ///   - text: The transcription text
    ///   - folderURL: The destination folder URL
    ///   - baseFilename: Base name for the files (without extension)
    func exportToFolder(screenshot: NSImage, text: String, folderURL: URL, baseFilename: String) {
        let sanitizedName = sanitizeFilename(baseFilename)
        let pngURL = folderURL.appendingPathComponent("\(sanitizedName).png")
        let mdURL = folderURL.appendingPathComponent("\(sanitizedName).md")

        // Save PNG
        if let tiffData = screenshot.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: pngURL)
                print("[ScreenshotService] Exported PNG: \(pngURL.lastPathComponent)")
            } catch {
                print("[ScreenshotService] Failed to export PNG: \(error)")
            }
        }

        // Save MD
        let title = extractTitle(from: text)
        let mdContent = """
        # \(title)

        ![\(title)](\(sanitizedName).png)

        ## Транскрипция

        \(text)

        ---
        *Создано в Говорилка*
        """

        do {
            try mdContent.write(to: mdURL, atomically: true, encoding: .utf8)
            print("[ScreenshotService] Exported MD: \(mdURL.lastPathComponent)")
        } catch {
            print("[ScreenshotService] Failed to export MD: \(error)")
        }
    }

    /// Extract title from text (first 1-3 words)
    /// - Parameter text: The full transcription text
    /// - Returns: Short title for filename
    func extractTitle(from text: String) -> String {
        let words = text.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
        let titleWords = words.prefix(3)
        let title = titleWords.joined(separator: " ")

        if title.isEmpty {
            return "Запись"
        }

        // Remove trailing punctuation
        return title.trimmingCharacters(in: .punctuationCharacters)
    }

    // MARK: - Private Methods

    /// Generate a unique filename for a screenshot
    private func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let uuid = UUID().uuidString.prefix(8)
        return "screenshot_\(timestamp)_\(uuid).png"
    }

    /// Transliterate Cyrillic text to Latin
    private func transliterate(_ text: String) -> String {
        let mutableString = NSMutableString(string: text)
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return mutableString as String
    }

    /// Sanitize filename by removing invalid characters and transliterating
    private func sanitizeFilename(_ filename: String) -> String {
        // Transliterate Cyrillic to Latin
        var sanitized = transliterate(filename)

        // Remove invalid filesystem characters
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:'")
        sanitized = sanitized.components(separatedBy: invalidCharacters).joined(separator: "")

        // Replace any whitespace (including Unicode spaces like \u202f) with underscores
        sanitized = sanitized.components(separatedBy: .whitespaces).joined(separator: "_")

        // Collapse multiple underscores
        while sanitized.contains("__") {
            sanitized = sanitized.replacingOccurrences(of: "__", with: "_")
        }

        // Trim leading/trailing underscores
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        // Truncate to reasonable length
        if sanitized.count > 50 {
            sanitized = String(sanitized.prefix(50))
        }

        return sanitized.isEmpty ? "export" : sanitized
    }

    /// Generate export base filename from timestamp and title
    func generateExportFilename(timestamp: Date, text: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: timestamp)
        let title = extractTitle(from: text)
        let sanitizedTitle = sanitizeFilename(title)
        return "\(dateString)_\(sanitizedTitle)"
    }
}
