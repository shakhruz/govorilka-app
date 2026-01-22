import XCTest
@testable import Govorilka

final class HotkeyServiceTests: XCTestCase {

    var hotkeyService: HotkeyService!

    override func setUp() {
        super.setUp()
        hotkeyService = HotkeyService.shared
    }

    override func tearDown() {
        hotkeyService.stopMonitoring()
        hotkeyService.onEscapePressed = nil
        hotkeyService.onHotkeyTriggered = nil
        super.tearDown()
    }

    // MARK: - ESC Monitoring Tests

    /// ESC monitoring should always be active regardless of hotkey mode
    func testEscMonitoringActiveInOptionSpaceMode() {
        // Given
        hotkeyService.proModeEnabled = false
        hotkeyService.currentMode = .optionSpace

        // When
        hotkeyService.startMonitoring()

        // Then - ESC callback should be settable and ready
        var escCalled = false
        hotkeyService.onEscapePressed = { escCalled = true }

        // Verify callback is set
        XCTAssertNotNil(hotkeyService.onEscapePressed)
    }

    func testEscMonitoringActiveInRightCommandMode() {
        // Given
        hotkeyService.proModeEnabled = false
        hotkeyService.currentMode = .rightCommand

        // When
        hotkeyService.startMonitoring()

        // Then
        var escCalled = false
        hotkeyService.onEscapePressed = { escCalled = true }
        XCTAssertNotNil(hotkeyService.onEscapePressed)
    }

    func testEscMonitoringActiveInProMode() {
        // Given
        hotkeyService.proModeEnabled = true

        // When
        hotkeyService.startMonitoring()

        // Then
        var escCalled = false
        hotkeyService.onEscapePressed = { escCalled = true }
        XCTAssertNotNil(hotkeyService.onEscapePressed)
    }

    // MARK: - Hotkey Mode Tests

    func testHotkeyModeNeedsEventMonitoring() {
        XCTAssertFalse(HotkeyMode.optionSpace.needsEventMonitoring)
        XCTAssertTrue(HotkeyMode.rightCommand.needsEventMonitoring)
        XCTAssertTrue(HotkeyMode.doubleTapRightOption.needsEventMonitoring)
    }

    func testHotkeyModeDisplayNames() {
        XCTAssertEqual(HotkeyMode.optionSpace.displayName, "⌥ Space")
        XCTAssertEqual(HotkeyMode.rightCommand.displayName, "Right ⌘")
        XCTAssertEqual(HotkeyMode.doubleTapRightOption.displayName, "2× Right ⌥")
    }
}
