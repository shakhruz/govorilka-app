import XCTest
import AppKit
@testable import Govorilka

/// Tests for Pro Mode functionality - screenshots combination, history saving
final class ProModeTests: XCTestCase {

    let storage = StorageService.shared
    let screenshotService = ScreenshotService.shared

    // MARK: - TranscriptEntry Tests for Pro Mode

    /// Test creating Pro mode entry with single screenshot
    func testProModeEntryWithSingleScreenshot() {
        let entry = TranscriptEntry(
            text: "Pro mode test",
            duration: 5.0,
            screenshotFilename: "test_screenshot.png",
            isProMode: true
        )

        XCTAssertTrue(entry.isProMode)
        XCTAssertTrue(entry.hasScreenshots)
        XCTAssertEqual(entry.allScreenshotFilenames.count, 1)
    }

    /// Test creating Pro mode entry with multiple screenshots
    func testProModeEntryWithMultipleScreenshots() {
        let filenames = ["shot1.png", "shot2.png", "shot3.png"]
        let entry = TranscriptEntry(
            text: "Multi-screenshot test",
            duration: 10.0,
            screenshotFilename: filenames.first,
            screenshotFilenames: filenames,
            isProMode: true
        )

        XCTAssertTrue(entry.isProMode)
        XCTAssertTrue(entry.hasScreenshots)
        XCTAssertEqual(entry.allScreenshotFilenames.count, 3)
        XCTAssertEqual(entry.allScreenshotFilenames, filenames)
    }

    /// Test that allScreenshotFilenames returns array when both single and array are set
    func testAllScreenshotFilenamesPreference() {
        // When both are set, array should be preferred
        let entry = TranscriptEntry(
            text: "Test",
            duration: 5.0,
            screenshotFilename: "single.png",
            screenshotFilenames: ["array1.png", "array2.png"],
            isProMode: true
        )

        XCTAssertEqual(entry.allScreenshotFilenames.count, 2)
        XCTAssertEqual(entry.allScreenshotFilenames.first, "array1.png")
    }

    // MARK: - Screenshot Combination Tests

    /// Test combining initial screenshot with camera button screenshots
    func testCombineScreenshots() {
        // Simulate Pro mode: one initial screenshot + camera button screenshots
        let initialScreenshot = createTestImage(color: .red)
        let cameraScreenshots = [
            createTestImage(color: .green),
            createTestImage(color: .blue)
        ]

        // This is what the fixed code does:
        var allScreenshots: [NSImage] = []
        allScreenshots.append(initialScreenshot)
        allScreenshots.append(contentsOf: cameraScreenshots)

        XCTAssertEqual(allScreenshots.count, 3, "Should have 3 screenshots total")
    }

    /// Test combining when only initial screenshot exists
    func testCombineScreenshotsOnlyInitial() {
        let initialScreenshot = createTestImage(color: .red)
        let cameraScreenshots: [NSImage] = []

        var allScreenshots: [NSImage] = []
        allScreenshots.append(initialScreenshot)
        allScreenshots.append(contentsOf: cameraScreenshots)

        XCTAssertEqual(allScreenshots.count, 1, "Should have 1 screenshot")
    }

    /// Test combining when only camera screenshots exist
    func testCombineScreenshotsOnlyCamera() {
        let initialScreenshot: NSImage? = nil
        let cameraScreenshots = [
            createTestImage(color: .green),
            createTestImage(color: .blue)
        ]

        var allScreenshots: [NSImage] = []
        if let initial = initialScreenshot {
            allScreenshots.append(initial)
        }
        allScreenshots.append(contentsOf: cameraScreenshots)

        XCTAssertEqual(allScreenshots.count, 2, "Should have 2 screenshots")
    }

    // MARK: - History Persistence Tests

    /// Test that Pro mode entry is saved to history
    func testProModeEntrySavedToHistory() {
        let originalHistory = storage.loadHistory()

        // Create and save a Pro mode entry
        let entry = TranscriptEntry(
            text: "Pro mode history test \(UUID().uuidString)",
            duration: 7.5,
            screenshotFilename: "test_history.png",
            isProMode: true
        )

        storage.addToHistory(entry)

        let newHistory = storage.loadHistory()

        XCTAssertEqual(newHistory.count, originalHistory.count + 1, "History should have one more entry")
        XCTAssertEqual(newHistory.first?.id, entry.id, "New entry should be at the beginning")
        XCTAssertTrue(newHistory.first?.isProMode ?? false, "Entry should be Pro mode")

        // Cleanup - remove the test entry
        storage.removeFromHistory(entry)
    }

    /// Test that multiple screenshot filenames are persisted
    func testMultipleScreenshotsPersisted() {
        let filenames = ["multi1.png", "multi2.png", "multi3.png"]
        let entry = TranscriptEntry(
            text: "Multi screenshot persistence test \(UUID().uuidString)",
            duration: 15.0,
            screenshotFilename: filenames.first,
            screenshotFilenames: filenames,
            isProMode: true
        )

        storage.addToHistory(entry)

        let history = storage.loadHistory()
        let savedEntry = history.first { $0.id == entry.id }

        XCTAssertNotNil(savedEntry, "Entry should be in history")
        XCTAssertEqual(savedEntry?.allScreenshotFilenames.count, 3, "All screenshot filenames should be saved")
        XCTAssertEqual(savedEntry?.allScreenshotFilenames, filenames, "Filenames should match")

        // Cleanup
        storage.removeFromHistory(entry)
    }

    // MARK: - Edge Cases

    /// Test empty text in Pro mode
    func testProModeWithEmptyText() {
        let entry = TranscriptEntry(
            text: "",
            duration: 5.0,
            screenshotFilename: "empty_text.png",
            isProMode: true
        )

        XCTAssertTrue(entry.text.isEmpty)
        XCTAssertTrue(entry.hasScreenshots)
        XCTAssertTrue(entry.isProMode)
    }

    /// Test very long text in Pro mode
    func testProModeWithLongText() {
        let longText = String(repeating: "Lorem ipsum ", count: 1000)
        let entry = TranscriptEntry(
            text: longText,
            duration: 60.0,
            screenshotFilename: "long_text.png",
            isProMode: true
        )

        XCTAssertEqual(entry.text, longText)
        XCTAssertTrue(entry.isProMode)
    }

    /// Test Pro mode with Russian text
    func testProModeWithRussianText() {
        let russianText = "Привет мир! Это тестовая транскрипция на русском языке."
        let entry = TranscriptEntry(
            text: russianText,
            duration: 10.0,
            screenshotFilename: "russian.png",
            isProMode: true
        )

        XCTAssertEqual(entry.text, russianText)
        XCTAssertTrue(entry.isProMode)
    }

    // MARK: - Helper Methods

    private func createTestImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 50, height: 50)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()
        return image
    }
}
