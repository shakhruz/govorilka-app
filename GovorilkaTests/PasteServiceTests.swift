import XCTest
import AppKit
@testable import Govorilka

/// Tests for PasteService - clipboard and auto-paste functionality
final class PasteServiceTests: XCTestCase {

    let pasteService = PasteService.shared
    let pasteboard = NSPasteboard.general

    override func setUp() {
        super.setUp()
        // Clear clipboard before each test
        pasteboard.clearContents()
    }

    // MARK: - Clipboard Tests

    /// Test that copyToClipboard puts text in the clipboard
    func testCopyToClipboard() {
        let testText = "Test text for clipboard \(UUID().uuidString)"

        pasteService.copyToClipboard(testText)

        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, testText, "Text should be copied to clipboard")
    }

    /// Test that setClipboard works with transient flag
    func testSetClipboardTransient() {
        let testText = "Transient test \(UUID().uuidString)"

        let result = pasteService.setClipboard(testText, transient: true)

        XCTAssertTrue(result, "setClipboard should return true")
        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, testText, "Text should be in clipboard")
    }

    /// Test that empty string clears clipboard content
    func testCopyEmptyStringClearsClipboard() {
        // First put something in clipboard
        pasteService.copyToClipboard("Initial content")
        XCTAssertNotNil(pasteboard.string(forType: .string))

        // Copy empty string
        pasteService.copyToClipboard("")

        // Clipboard should now be empty or have empty string
        let content = pasteboard.string(forType: .string)
        XCTAssertTrue(content == nil || content == "", "Clipboard should be empty after copying empty string")
    }

    /// Test that image can be copied to clipboard
    func testCopyImageToClipboard() {
        // Create a simple test image
        let size = NSSize(width: 10, height: 10)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()

        pasteService.copyImageToClipboard(image)

        // Verify image is in clipboard
        let hasImage = pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.tiff.rawValue])
        XCTAssertTrue(hasImage, "Image should be in clipboard")
    }

    // MARK: - Accessibility Tests

    /// Test that hasAccessibilityPermission returns a boolean
    func testHasAccessibilityPermissionReturnsBoolean() {
        let hasPermission = pasteService.hasAccessibilityPermission()

        // We can't guarantee the result, but it should be a valid boolean
        XCTAssertTrue(hasPermission == true || hasPermission == false, "Should return a boolean")

        // Log the result for debugging
        print("[TEST] Accessibility permission: \(hasPermission)")
    }

    /// Test that checkAccessibilityPermission works with prompt=false
    func testCheckAccessibilityPermissionWithoutPrompt() {
        // This should not show a dialog when prompt=false
        let hasPermission = pasteService.checkAccessibilityPermission(prompt: false)

        // Result should match hasAccessibilityPermission
        XCTAssertEqual(hasPermission, pasteService.hasAccessibilityPermission())
    }

    // MARK: - Paste Integration Tests

    /// Test pasteAtCursor with text (integration test - requires accessibility)
    func testPasteAtCursorSetsClipboard() {
        let testText = "Paste test \(UUID().uuidString)"

        // This will put text in clipboard even if paste fails due to permissions
        pasteService.pasteAtCursor(testText, restoreClipboard: false)

        // Give it a moment to execute
        let expectation = XCTestExpectation(description: "Clipboard set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let clipboardContent = self.pasteboard.string(forType: .string)
            XCTAssertEqual(clipboardContent, testText, "Text should be in clipboard before paste")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Edge Cases

    /// Test copying special characters
    func testCopySpecialCharacters() {
        let specialText = "Привет! 你好 🎉 <script>alert('xss')</script>"

        pasteService.copyToClipboard(specialText)

        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, specialText, "Special characters should be preserved")
    }

    /// Test copying very long text
    func testCopyLongText() {
        let longText = String(repeating: "Lorem ipsum ", count: 10000)

        pasteService.copyToClipboard(longText)

        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, longText, "Long text should be fully copied")
    }

    /// Test copying multiline text
    func testCopyMultilineText() {
        let multilineText = """
        Line 1
        Line 2
        Line 3 with special chars: <>&"'
        """

        pasteService.copyToClipboard(multilineText)

        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, multilineText, "Multiline text should be preserved")
    }
}
