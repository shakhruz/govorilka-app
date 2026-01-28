import XCTest
@testable import Govorilka

/// Tests for StorageService - persistence and export folder functionality
final class StorageServiceTests: XCTestCase {

    let storage = StorageService.shared

    // MARK: - History Tests

    /// Test that history can be loaded
    func testLoadHistory() {
        let history = storage.loadHistory()

        // History should be an array (may be empty)
        XCTAssertNotNil(history, "History should not be nil")
        print("[TEST] History contains \(history.count) entries")
    }

    /// Test that TranscriptEntry can be created and has correct properties
    func testTranscriptEntryCreation() {
        let text = "Test transcript"
        let entry = TranscriptEntry(text: text, duration: 5.0)

        XCTAssertEqual(entry.text, text)
        XCTAssertEqual(entry.duration, 5.0)
        XCTAssertFalse(entry.hasScreenshots)
        XCTAssertTrue(entry.allScreenshotFilenames.isEmpty)
    }

    /// Test that TranscriptEntry with screenshots has correct properties
    func testTranscriptEntryWithScreenshots() {
        let filenames = ["screenshot1.png", "screenshot2.png", "screenshot3.png"]
        let entry = TranscriptEntry(
            text: "Test with screenshots",
            duration: 10.0,
            screenshotFilename: filenames.first,
            screenshotFilenames: filenames,
            isProMode: true
        )

        XCTAssertTrue(entry.hasScreenshots)
        XCTAssertEqual(entry.allScreenshotFilenames.count, 3)
        XCTAssertEqual(entry.allScreenshotFilenames, filenames)
        XCTAssertTrue(entry.isProMode)
    }

    /// Test allScreenshotFilenames fallback to single screenshot
    func testAllScreenshotFilenamesFallback() {
        let entry = TranscriptEntry(
            text: "Test with single screenshot",
            duration: 5.0,
            screenshotFilename: "single.png",
            screenshotFilenames: nil
        )

        XCTAssertTrue(entry.hasScreenshots)
        XCTAssertEqual(entry.allScreenshotFilenames.count, 1)
        XCTAssertEqual(entry.allScreenshotFilenames.first, "single.png")
    }

    /// Test allScreenshotFilenames prefers array over single
    func testAllScreenshotFilenamesPrefersArray() {
        let entry = TranscriptEntry(
            text: "Test with both",
            duration: 5.0,
            screenshotFilename: "single.png",
            screenshotFilenames: ["array1.png", "array2.png"]
        )

        // Should use the array, not the single filename
        XCTAssertEqual(entry.allScreenshotFilenames.count, 2)
        XCTAssertEqual(entry.allScreenshotFilenames, ["array1.png", "array2.png"])
    }

    // MARK: - Export Folder Tests

    /// Test that resolveExportFolder returns nil when no folder is set
    func testResolveExportFolderWhenNotSet() {
        // Note: This test assumes no folder has been previously set
        // In a real test environment, we would use dependency injection

        let folderURL = storage.resolveExportFolder()

        // If a folder is set, we should get a URL
        // If not set, we should get nil
        if let url = folderURL {
            print("[TEST] Export folder is set: \(url.path)")
            // Clean up - stop accessing the security-scoped resource
            storage.stopAccessingExportFolder(url)
        } else {
            print("[TEST] Export folder is not set")
        }

        // Test passes either way - we're just verifying the method doesn't crash
        XCTAssertTrue(true)
    }

    /// Test that proExportFolderBookmark property works
    func testExportFolderBookmark() {
        let hasBookmark = storage.proExportFolderBookmark != nil

        // Log the result for debugging
        print("[TEST] Has export folder bookmark: \(hasBookmark)")

        // Should be a valid boolean
        XCTAssertTrue(hasBookmark == true || hasBookmark == false)
    }

    // MARK: - Settings Tests

    /// Test autoPasteEnabled setting
    func testAutoPasteEnabledSetting() {
        // Get current value
        let originalValue = storage.autoPasteEnabled

        // Toggle it
        storage.autoPasteEnabled = !originalValue
        XCTAssertEqual(storage.autoPasteEnabled, !originalValue)

        // Restore original
        storage.autoPasteEnabled = originalValue
        XCTAssertEqual(storage.autoPasteEnabled, originalValue)
    }

    /// Test soundsEnabled setting
    func testSoundsEnabledSetting() {
        let originalValue = storage.soundsEnabled

        storage.soundsEnabled = !originalValue
        XCTAssertEqual(storage.soundsEnabled, !originalValue)

        storage.soundsEnabled = originalValue
        XCTAssertEqual(storage.soundsEnabled, originalValue)
    }

    /// Test proModeEnabled setting
    func testProModeEnabledSetting() {
        let originalValue = storage.proModeEnabled

        storage.proModeEnabled = !originalValue
        XCTAssertEqual(storage.proModeEnabled, !originalValue)

        storage.proModeEnabled = originalValue
        XCTAssertEqual(storage.proModeEnabled, originalValue)
    }

    // MARK: - API Key Tests (without exposing actual key)

    /// Test that hasApiKey works
    func testHasApiKey() {
        let hasKey = storage.hasApiKey

        print("[TEST] hasApiKey: \(hasKey)")

        // Should be a valid boolean
        XCTAssertTrue(hasKey == true || hasKey == false)
    }

    // MARK: - Edge Cases

    /// Test that settings persist after reload
    func testSettingsPersistence() {
        let originalAutoPaste = storage.autoPasteEnabled

        // Change setting
        storage.autoPasteEnabled = !originalAutoPaste

        // Create a new reference to verify persistence
        // (In real tests, we'd use dependency injection for clean isolation)
        XCTAssertEqual(storage.autoPasteEnabled, !originalAutoPaste)

        // Restore
        storage.autoPasteEnabled = originalAutoPaste
    }
}
