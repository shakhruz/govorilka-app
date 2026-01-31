import XCTest
import AppKit
@testable import Govorilka

/// Tests for ScreenshotService - screenshot capture, save, and export functionality
final class ScreenshotServiceTests: XCTestCase {

    let screenshotService = ScreenshotService.shared

    // MARK: - Screenshot Creation Tests

    /// Test that a test image can be created
    func testCreateTestImage() {
        let image = createTestImage(size: NSSize(width: 100, height: 100), color: .red)

        XCTAssertNotNil(image)
        XCTAssertEqual(image.size.width, 100)
        XCTAssertEqual(image.size.height, 100)
    }

    /// Test that screenshot can be saved to app storage
    func testSaveScreenshot() {
        let image = createTestImage(size: NSSize(width: 50, height: 50), color: .blue)

        let filename = screenshotService.saveScreenshot(image)

        XCTAssertNotNil(filename, "Screenshot should be saved and return a filename")
        XCTAssertTrue(filename?.hasSuffix(".png") ?? false, "Filename should be PNG")

        // Cleanup
        if let filename = filename {
            screenshotService.deleteScreenshot(filename: filename)
        }
    }

    /// Test that saved screenshot can be loaded
    func testLoadScreenshot() {
        let originalImage = createTestImage(size: NSSize(width: 50, height: 50), color: .green)

        guard let filename = screenshotService.saveScreenshot(originalImage) else {
            XCTFail("Failed to save screenshot")
            return
        }

        let loadedImage = screenshotService.loadScreenshot(filename: filename)

        XCTAssertNotNil(loadedImage, "Screenshot should be loadable")

        // Cleanup
        screenshotService.deleteScreenshot(filename: filename)
    }

    /// Test that multiple screenshots can be saved
    func testSaveMultipleScreenshots() {
        let images = [
            createTestImage(size: NSSize(width: 50, height: 50), color: .red),
            createTestImage(size: NSSize(width: 50, height: 50), color: .green),
            createTestImage(size: NSSize(width: 50, height: 50), color: .blue)
        ]

        var savedFilenames: [String] = []

        for image in images {
            if let filename = screenshotService.saveScreenshot(image) {
                savedFilenames.append(filename)
            }
        }

        XCTAssertEqual(savedFilenames.count, 3, "All screenshots should be saved")

        // Verify all are unique
        let uniqueFilenames = Set(savedFilenames)
        XCTAssertEqual(uniqueFilenames.count, 3, "All filenames should be unique")

        // Cleanup
        for filename in savedFilenames {
            screenshotService.deleteScreenshot(filename: filename)
        }
    }

    /// Test that deleted screenshot cannot be loaded
    func testDeleteScreenshot() {
        let image = createTestImage(size: NSSize(width: 50, height: 50), color: .orange)

        guard let filename = screenshotService.saveScreenshot(image) else {
            XCTFail("Failed to save screenshot")
            return
        }

        // Verify it exists
        XCTAssertNotNil(screenshotService.loadScreenshot(filename: filename))

        // Delete it
        screenshotService.deleteScreenshot(filename: filename)

        // Verify it's gone
        XCTAssertNil(screenshotService.loadScreenshot(filename: filename), "Deleted screenshot should not be loadable")
    }

    // MARK: - Export Filename Tests

    /// Test export filename generation
    func testGenerateExportFilename() {
        let timestamp = Date()
        let text = "Test transcript text"

        let filename = screenshotService.generateExportFilename(timestamp: timestamp, text: text)

        XCTAssertFalse(filename.isEmpty, "Filename should not be empty")
        XCTAssertFalse(filename.contains("/"), "Filename should not contain path separators")
        XCTAssertFalse(filename.contains(":"), "Filename should not contain colons")
    }

    /// Test export filename with Russian text
    func testGenerateExportFilenameRussian() {
        let timestamp = Date()
        let text = "Привет мир тестирование"

        let filename = screenshotService.generateExportFilename(timestamp: timestamp, text: text)

        XCTAssertFalse(filename.isEmpty, "Filename should not be empty")
        // Should be transliterated
        print("[TEST] Generated filename for Russian text: \(filename)")
    }

    /// Test export filename with special characters
    func testGenerateExportFilenameSpecialChars() {
        let timestamp = Date()
        let text = "Test <script>alert('xss')</script> & more"

        let filename = screenshotService.generateExportFilename(timestamp: timestamp, text: text)

        XCTAssertFalse(filename.contains("<"), "Filename should not contain <")
        XCTAssertFalse(filename.contains(">"), "Filename should not contain >")
        XCTAssertFalse(filename.contains("'"), "Filename should not contain quotes")
    }

    // MARK: - Helper Methods

    private func createTestImage(size: NSSize, color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }
}
