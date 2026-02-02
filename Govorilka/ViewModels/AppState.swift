import AppKit
import Combine
import Foundation
import KeyboardShortcuts
import SwiftUI

// Define keyboard shortcut name
extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.space, modifiers: .option))
}

/// Main application state management
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var isRecording = false
    @Published var currentTranscript = ""
    @Published var interimTranscript = "" // Real-time preview
    @Published var history: [TranscriptEntry] = []
    @Published var errorMessage: String?
    @Published var showError = false

    // Settings
    @Published var apiKey: String = ""
    @Published var autoPasteEnabled: Bool = true
    @Published var hasAccessibilityPermission = false
    @Published var hasScreenRecordingPermission = false
    @Published var hotkeyMode: HotkeyMode = .optionSpace

    // Connection status
    @Published var isConnecting = false
    @Published var isConnected = false

    // Audio level for waveform visualization
    @Published var currentAudioLevel: Float = 0.0

    // Floating window
    @Published var showFloatingWindow = true // User preference
    let floatingWindowController = FloatingWindowController()

    // Pro mode
    @Published var proModeEnabled = false
    @Published var textCleaningEnabled = true
    @Published var soundsEnabled = true

    // In-recording screenshots (captured via camera button)
    @Published var capturedScreenshots: [NSImage] = []
    let proReviewController = ProReviewWindowController()
    private var pendingScreenshot: NSImage?
    private var pendingDuration: TimeInterval = 0
    private var isProRecording = false  // Flag: current recording is Pro (with screenshot)
    private let screenshotService = ScreenshotService.shared

    // Accessibility onboarding
    let onboardingWindowController = OnboardingWindowController()

    // Flag to suppress errors during intentional disconnect
    private var isDisconnecting = false

    // Flag to prevent re-entry during async stop process
    private var isStopping = false

    // Fallback recording state
    private var backupFileURL: URL?
    @Published var isRetrying = false
    @Published var showRetryOption = false
    private var pendingFallbackDuration: TimeInterval = 0

    // MARK: - Services

    private let audioService = AudioService()
    private let deepgramService = DeepgramService()
    private let pasteService = PasteService.shared
    private let storage = StorageService.shared
    private let hotkeyService = HotkeyService.shared
    private let textCleaner = TextCleanerService.shared
    private let soundService = SoundService.shared
    private let localRecorder = LocalRecorderService.shared
    private let deepgramHTTP = DeepgramHTTPService.shared

    // Recording state
    private var recordingStartTime: Date?

    // MARK: - Initialization

    init() {
        // Load saved settings
        apiKey = storage.apiKey ?? ""
        autoPasteEnabled = storage.autoPasteEnabled
        showFloatingWindow = storage.showFloatingWindow
        hotkeyMode = storage.hotkeyMode
        proModeEnabled = storage.proModeEnabled
        textCleaningEnabled = storage.textCleaningEnabled
        soundsEnabled = storage.soundsEnabled
        history = storage.loadHistory()
        hasAccessibilityPermission = pasteService.hasAccessibilityPermission()
        hasScreenRecordingPermission = screenshotService.hasScreenRecordingPermission()

        // Set up delegates
        audioService.delegate = self
        deepgramService.delegate = self

        // Set up keyboard shortcut (Option + Space)
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.proModeEnabled {
                    // Pro mode: Option+Space = screenshot + feedback
                    self.toggleProRecording()
                } else if self.hotkeyMode == .optionSpace {
                    // Normal mode: Option+Space = voice input
                    self.toggleRecording()
                }
            }
        }

        // Set up hotkey service for special modes
        hotkeyService.onHotkeyTriggered = { [weak self] in
            Task { @MainActor in
                // This is triggered by Right Command in Pro mode, or selected hotkey in normal mode
                self?.toggleRecording()
            }
        }

        // ESC для отмены записи
        hotkeyService.onEscapePressed = { [weak self] in
            Task { @MainActor in
                if self?.isRecording == true {
                    self?.cancelRecording()
                }
            }
        }

        hotkeyService.currentMode = hotkeyMode
        hotkeyService.proModeEnabled = proModeEnabled
        hotkeyService.startMonitoring()

        // Show accessibility onboarding if needed
        if !hasAccessibilityPermission && !storage.accessibilityOnboardingSkipped {
            // Delay slightly to let the app finish launching
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showAccessibilityOnboarding()
            }
        }
    }

    // MARK: - Accessibility Onboarding

    /// Show the accessibility onboarding window
    func showAccessibilityOnboarding() {
        onboardingWindowController.show()
    }

    // MARK: - Public Methods

    /// Toggle recording on/off (normal voice input, no screenshot)
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            isProRecording = false
            capturedScreenshots = []  // Clear any previous screenshots
            startRecording(withScreenshot: false)
        }
    }

    /// Toggle Pro recording (screenshot + feedback)
    func toggleProRecording() {
        if isRecording {
            stopRecording()
        } else {
            isProRecording = true
            startRecording(withScreenshot: true)
        }
    }

    /// Start recording
    /// - Parameter withScreenshot: If true, captures screenshot before recording (Pro mode)
    func startRecording(withScreenshot: Bool = false) {
        guard !isRecording else { return }

        // Check for API key
        guard storage.hasApiKey else {
            showError(message: "Добавьте API ключ Deepgram в настройках")
            return
        }

        // Request microphone permission
        Task {
            let hasPermission = await audioService.requestPermission()

            guard hasPermission else {
                await MainActor.run {
                    showMicrophonePermissionAlert()
                }
                return
            }

            // Capture screenshot BEFORE recording if Pro mode
            if withScreenshot {
                // Try to capture - if it succeeds, permission is granted
                if let screenshot = await screenshotService.captureScreen() {
                    pendingScreenshot = screenshot
                    screenshotCaptureVerified = true
                    print("[AppState] Pro recording: screenshot captured")
                } else if !screenshotCaptureVerified {
                    // Capture failed and we haven't verified permission before
                    // Show permission alert (CGPreflightScreenCaptureAccess is unreliable)
                    await MainActor.run {
                        showScreenRecordingPermissionAlert()
                    }
                    return
                } else {
                    // Capture failed but we've had success before - just continue
                    print("[AppState] Pro recording: screenshot capture failed, continuing without")
                }
            }

            // Connect to Deepgram
            isConnecting = true

            do {
                try deepgramService.connect()
            } catch {
                isConnecting = false
                pendingScreenshot = nil
                isProRecording = false
                showError(message: error.localizedDescription)
            }
        }
    }

    /// Stop recording
    func stopRecording() {
        guard isRecording, !isStopping else { return }

        // Set flags immediately to prevent re-entry
        isStopping = true
        isRecording = false
        isDisconnecting = true

        // Play stop sound
        soundService.play(.stop)

        // Hide floating window
        floatingWindowController.hide()

        // Capture current state for async processing
        let wasProRecording = isProRecording
        let screenshot = pendingScreenshot
        let screenshots = capturedScreenshots

        // Reset UI state immediately
        currentAudioLevel = 0.0

        // Add trailing buffer delay to capture remaining audio
        // Continue recording for 400ms to avoid cutting off the end
        Task {
            // Wait for trailing audio to be captured and sent
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 sec

            await MainActor.run {
                // Stop audio capture after trailing delay
                let duration = audioService.stopRecording()

                // Signal end of stream to Deepgram
                deepgramService.finishStream()

                // Wait a bit more for final transcript from Deepgram
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 sec

                    await MainActor.run {
                        finalizeStopRecording(
                            duration: duration,
                            wasProRecording: wasProRecording,
                            screenshot: screenshot,
                            screenshots: screenshots
                        )
                    }
                }
            }
        }
    }

    /// Finalize stop recording - process transcript and clean up
    private func finalizeStopRecording(
        duration: TimeInterval,
        wasProRecording: Bool,
        screenshot: NSImage?,
        screenshots: [NSImage]
    ) {
        // Save final transcript if we have one
        var finalText = currentTranscript.isEmpty ? interimTranscript : currentTranscript

        // Clean text from filler words if enabled
        if textCleaningEnabled && !finalText.isEmpty {
            finalText = textCleaner.clean(finalText)
        }

        // Disconnect (this will close the WebSocket)
        deepgramService.disconnect()

        // Finish and clean up local backup (transcription succeeded via WebSocket)
        if let backupURL = localRecorder.finishRecording() {
            localRecorder.deleteBackup(backupURL)
        }
        backupFileURL = nil

        // Reset state
        isConnected = false
        currentTranscript = ""
        interimTranscript = ""
        recordingStartTime = nil
        pendingScreenshot = nil
        isProRecording = false
        capturedScreenshots = []
        isStopping = false

        // Combine Pro mode initial screenshot with camera button screenshots
        var allScreenshots: [NSImage] = []
        if let proScreenshot = screenshot {
            allScreenshots.append(proScreenshot)
        }
        allScreenshots.append(contentsOf: screenshots)

        // Pro mode or camera button screenshots: show review dialog
        if !allScreenshots.isEmpty && !finalText.isEmpty {
            pendingDuration = duration
            handleMultiScreenshotFeedback(screenshots: allScreenshots, text: finalText, duration: duration)

            // Reset disconnect flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isDisconnecting = false
            }
            return
        }

        // Process the transcript (standard flow)
        if !finalText.isEmpty {
            let entry = TranscriptEntry(
                text: finalText,
                duration: duration
            )

            // Add to history
            history.insert(entry, at: 0)
            storage.addToHistory(entry)

            // Auto-paste if enabled, otherwise just copy to clipboard
            if autoPasteEnabled {
                let canPaste = pasteService.hasAccessibilityPermission()
                hasAccessibilityPermission = canPaste

                print("[AppState] Auto-paste enabled, has permission: \(canPaste)")

                if canPaste {
                    // Use pasteAtCursor - it handles clipboard, paste, and restoration
                    // Delay to ensure floating window is fully hidden and target app regains focus
                    let frontAppBefore = NSWorkspace.shared.frontmostApplication
                    print("[AppState] 📋 Before paste delay - frontmost app: \(frontAppBefore?.localizedName ?? "unknown")")

                    // Increased delay from 0.25 to 0.5 for better focus handling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        guard let self = self else { return }

                        let frontAppNow = NSWorkspace.shared.frontmostApplication
                        print("[AppState] 📋 After delay - frontmost app: \(frontAppNow?.localizedName ?? "unknown")")

                        // Check that Govorilka is NOT the frontmost app
                        if frontAppNow?.bundleIdentifier == Bundle.main.bundleIdentifier {
                            print("[AppState] ❌ Cannot paste: Govorilka is still frontmost, copying to clipboard only")
                            self.pasteService.copyToClipboard(finalText)
                            self.soundService.play(.success)
                            return
                        }

                        print("[AppState] 📋 Triggering pasteAtCursor with text: \"\(finalText.prefix(50))...\"")
                        self.pasteService.pasteAtCursor(finalText, restoreClipboard: true)
                        // Play success sound after paste
                        self.soundService.play(.success)
                    }
                } else {
                    // No permission - just copy to clipboard
                    print("[AppState] No accessibility permission, copying to clipboard only")
                    pasteService.copyToClipboard(finalText)
                }
            } else {
                // Auto-paste disabled - just copy to clipboard
                pasteService.copyToClipboard(finalText)
            }
        }

        // Reset disconnect flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isDisconnecting = false
        }
    }

    // MARK: - Pro Mode Handlers

    /// Handle save from Pro review dialog
    private func handleProSave(data: ProReviewData) {
        // Save screenshot to app storage
        guard let filename = screenshotService.saveScreenshot(data.screenshot) else {
            print("[AppState] Failed to save screenshot")
            return
        }

        // Create entry with screenshot
        let entry = TranscriptEntry(
            text: data.transcript,
            timestamp: data.timestamp,
            duration: data.duration,
            screenshotFilename: filename,
            isProMode: true
        )

        // Add to history
        history.insert(entry, at: 0)
        storage.addToHistory(entry)

        // Always export to folder
        var exportedFolderName: String?
        if let folderURL = storage.resolveExportFolder() {
            let baseFilename = screenshotService.generateExportFilename(
                timestamp: data.timestamp,
                text: data.transcript
            )
            screenshotService.exportToFolder(
                screenshot: data.screenshot,
                text: data.transcript,
                folderURL: folderURL,
                baseFilename: baseFilename
            )
            exportedFolderName = folderURL.lastPathComponent
            storage.stopAccessingExportFolder(folderURL)
        }

        // Copy text to clipboard (don't auto-paste in Pro mode)
        pasteService.copyToClipboard(data.transcript)

        print("[AppState] Pro save completed: \(filename)")

        // Show confirmation alert
        showSaveConfirmation(folderName: exportedFolderName)
    }

    /// Handle cancel from Pro review dialog
    private func handleProCancel() {
        print("[AppState] Pro review cancelled")
        // Don't save anything
    }

    /// Handle multiple screenshots captured during recording (camera button)
    private func handleMultiScreenshotFeedback(screenshots: [NSImage], text: String, duration: TimeInterval) {
        // Show review dialog with all screenshots
        proReviewController.show(
            screenshots: screenshots,
            transcript: text,
            duration: duration,
            onSave: { [weak self] data in
                self?.handleMultiScreenshotSave(data: data)
            },
            onCancel: { [weak self] in
                self?.handleProCancel()
            }
        )
    }

    /// Handle save from multi-screenshot review dialog
    private func handleMultiScreenshotSave(data: ProReviewData) {
        // Save ALL screenshots to app storage
        var savedFilenames: [String] = []
        for screenshot in data.screenshots {
            if let filename = screenshotService.saveScreenshot(screenshot) {
                savedFilenames.append(filename)
            }
        }

        guard !savedFilenames.isEmpty else {
            print("[AppState] Failed to save any screenshots")
            return
        }

        // Create entry with all screenshots
        let entry = TranscriptEntry(
            text: data.transcript,
            timestamp: data.timestamp,
            duration: data.duration,
            screenshotFilename: savedFilenames.first,  // Backward compatibility
            screenshotFilenames: savedFilenames,        // All screenshots
            isProMode: true
        )

        // Add to history
        history.insert(entry, at: 0)
        storage.addToHistory(entry)

        // Export all screenshots to folder
        var exportedFolderName: String?
        if let folderURL = storage.resolveExportFolder() {
            let baseFilename = screenshotService.generateExportFilename(
                timestamp: data.timestamp,
                text: data.transcript
            )

            // Export each screenshot with numbered suffix
            for (index, screenshot) in data.screenshots.enumerated() {
                let suffix = data.screenshots.count > 1 ? "_\(index + 1)" : ""
                let filename = "\(baseFilename)\(suffix)"
                screenshotService.exportToFolder(
                    screenshot: screenshot,
                    text: index == 0 ? data.transcript : "", // Only include text with first screenshot
                    folderURL: folderURL,
                    baseFilename: filename
                )
            }

            exportedFolderName = folderURL.lastPathComponent
            storage.stopAccessingExportFolder(folderURL)
        }

        // Copy text to clipboard
        pasteService.copyToClipboard(data.transcript)

        // Play success sound
        soundService.play(.success)

        print("[AppState] Multi-screenshot feedback saved: \(data.screenshots.count) screenshots")

        // Show confirmation alert
        showSaveConfirmation(folderName: exportedFolderName)
    }

    /// Show confirmation alert after saving
    private func showSaveConfirmation(folderName: String?) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Сохранено"

        if let folder = folderName {
            alert.informativeText = "Файлы сохранены в папку «\(folder)»"
        } else {
            alert.informativeText = "Запись сохранена в историю"
        }

        alert.addButton(withTitle: "OK")

        // Show alert in front
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    /// Cancel recording without saving/pasting
    func cancelRecording() {
        guard isRecording else { return }

        // Set flag to suppress disconnect errors
        isDisconnecting = true

        // Hide floating window
        floatingWindowController.hide()

        // Stop audio capture (ignore duration)
        _ = audioService.stopRecording()

        // Cancel local backup recording
        localRecorder.cancelRecording()
        backupFileURL = nil

        // Disconnect
        deepgramService.disconnect()

        // Reset state without saving
        isRecording = false
        isConnected = false
        currentTranscript = ""
        interimTranscript = ""
        currentAudioLevel = 0.0
        recordingStartTime = nil
        pendingScreenshot = nil
        isProRecording = false
        capturedScreenshots = []

        // Reset disconnect flag after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isDisconnecting = false
        }
    }

    /// Copy specific entry to clipboard
    func copyEntry(_ entry: TranscriptEntry) {
        pasteService.copyToClipboard(entry.text)
    }

    /// Delete entry from history
    func deleteEntry(_ entry: TranscriptEntry) {
        // Delete all screenshots
        for filename in entry.allScreenshotFilenames {
            screenshotService.deleteScreenshot(filename: filename)
        }
        history.removeAll { $0.id == entry.id }
        storage.removeFromHistory(entry)
    }

    /// Clear all history
    func clearHistory() {
        history.removeAll()
        storage.clearHistory()
    }

    /// Save API key
    func saveApiKey(_ key: String) {
        apiKey = key
        storage.apiKey = key
    }

    /// Save auto-paste setting
    func saveAutoPaste(_ enabled: Bool) {
        autoPasteEnabled = enabled
        storage.autoPasteEnabled = enabled
    }

    /// Save floating window setting
    func saveShowFloatingWindow(_ enabled: Bool) {
        showFloatingWindow = enabled
        storage.showFloatingWindow = enabled
    }

    /// Save hotkey mode
    func saveHotkeyMode(_ mode: HotkeyMode) {
        hotkeyMode = mode
        storage.hotkeyMode = mode
        hotkeyService.currentMode = mode
        hotkeyService.startMonitoring()
    }

    /// Save Pro mode setting
    func saveProModeEnabled(_ enabled: Bool) {
        proModeEnabled = enabled
        storage.proModeEnabled = enabled
        hotkeyService.proModeEnabled = enabled
        hotkeyService.startMonitoring()
    }

    /// Save text cleaning setting
    func saveTextCleaningEnabled(_ enabled: Bool) {
        textCleaningEnabled = enabled
        storage.textCleaningEnabled = enabled
    }

    /// Save sounds setting
    func saveSoundsEnabled(_ enabled: Bool) {
        soundsEnabled = enabled
        storage.soundsEnabled = enabled
    }

    /// Save LLM API key
    func saveLLMApiKey(_ key: String) {
        storage.llmApiKey = key
    }

    /// Save export folder
    func saveExportFolder(_ url: URL) {
        storage.saveExportFolder(url)
    }

    /// Flag to track if screenshot capture has ever succeeded (permission workaround)
    private var screenshotCaptureVerified = false

    /// Capture screenshot during recording (camera button)
    func captureScreenshotDuringRecording() {
        guard isRecording else { return }

        // Check permission first (but skip if we've already captured successfully)
        if !screenshotCaptureVerified && !screenshotService.hasScreenRecordingPermission() {
            showScreenRecordingPermissionAlert()
            return
        }

        // Temporarily hide floating window (don't destroy it)
        floatingWindowController.temporaryHide()

        Task {
            // Small delay to ensure window is hidden
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 sec

            // Capture screenshot
            if let screenshot = await screenshotService.captureScreen() {
                await MainActor.run {
                    screenshotCaptureVerified = true  // Mark as verified
                    capturedScreenshots.append(screenshot)
                    print("[AppState] Screenshot captured during recording: \(capturedScreenshots.count) total")

                    // Play success sound
                    soundService.play(.success)
                }
            } else {
                await MainActor.run {
                    print("[AppState] Screenshot capture failed")
                    soundService.play(.error)
                }
            }

            // Small delay before showing window again
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec

            // Show floating window again
            await MainActor.run {
                if isRecording {
                    floatingWindowController.temporaryShow()
                }
            }
        }
    }

    /// Show friendly alert for Screen Recording permission
    private func showScreenRecordingPermissionAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Нужен доступ к экрану"
        alert.informativeText = """
        Чтобы делать скриншоты:

        1. Откройте Настройки → Конфиденциальность → Запись экрана
        2. Найдите «Govorilka» и включите тумблер
        3. Перезапустите Говорилку

        После включения нужен перезапуск!
        """
        alert.addButton(withTitle: "Открыть настройки")
        alert.addButton(withTitle: "Позже")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            screenshotService.openScreenRecordingSettings()
        }
    }

    /// Show friendly alert for Microphone permission
    private func showMicrophonePermissionAlert() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Нужен доступ к микрофону"
        alert.informativeText = """
        Чтобы использовать голосовой ввод:

        1. Откройте Настройки → Конфиденциальность → Микрофон
        2. Найдите «Govorilka» и включите тумблер
        3. Попробуйте записать снова

        Если приложения нет в списке, нажмите «+» и добавьте его.
        """
        alert.addButton(withTitle: "Открыть настройки")
        alert.addButton(withTitle: "Позже")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            audioService.openMicrophoneSettings()
        }
    }

    /// Request accessibility permission - opens System Settings directly
    func requestAccessibility() {
        // Open System Settings directly - the prompt dialog only works once
        pasteService.openAccessibilitySettings()
        // Check again after a delay (user might grant permission)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hasAccessibilityPermission = self?.pasteService.hasAccessibilityPermission() ?? false
        }
    }

    /// Refresh accessibility permission status
    func refreshAccessibilityStatus() {
        hasAccessibilityPermission = pasteService.hasAccessibilityPermission()
    }

    /// Refresh screen recording permission status
    func refreshScreenRecordingStatus() {
        hasScreenRecordingPermission = screenshotService.hasScreenRecordingPermission()
    }

    /// Open Screen Recording settings
    func openScreenRecordingSettings() {
        screenshotService.openScreenRecordingSettings()
        // Check again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshScreenRecordingStatus()
        }
    }

    /// Current recording duration
    var recordingDuration: TimeInterval {
        recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
    }

    // MARK: - Private Methods

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - AudioServiceDelegate

extension AppState: AudioServiceDelegate {
    nonisolated func audioService(_ service: AudioService, didReceiveAudioData data: Data) {
        // Forward audio to Deepgram
        deepgramService.sendAudio(data)
        // Also save to local backup
        localRecorder.appendAudio(data)
    }

    nonisolated func audioService(_ service: AudioService, didFailWithError error: Error) {
        Task { @MainActor in
            showError(message: error.localizedDescription)
            stopRecording()
        }
    }

    nonisolated func audioService(_ service: AudioService, didUpdateAudioLevel level: Float) {
        Task { @MainActor in
            currentAudioLevel = level
        }
    }
}

// MARK: - DeepgramServiceDelegate

extension AppState: DeepgramServiceDelegate {
    nonisolated func deepgramService(_ service: DeepgramService, didReceiveTranscript text: String, isFinal: Bool) {
        Task { @MainActor in
            if isFinal {
                // Append final transcript
                if !currentTranscript.isEmpty {
                    currentTranscript += " "
                }
                currentTranscript += text
                interimTranscript = ""
            } else {
                // Update interim transcript
                interimTranscript = text
            }
        }
    }

    nonisolated func deepgramService(_ service: DeepgramService, didFailWithError error: Error) {
        Task { @MainActor in
            // Ignore errors during intentional disconnect
            guard !isDisconnecting else { return }

            // Play error sound
            soundService.play(.error)

            // Stop audio and save backup
            let duration = audioService.stopRecording()
            let backupURL = localRecorder.finishRecording()

            // Hide floating window
            floatingWindowController.hide()

            // Reset state
            isRecording = false
            isConnected = false
            currentAudioLevel = 0.0
            recordingStartTime = nil

            // If we have a backup, offer retry option
            if let backup = backupURL {
                backupFileURL = backup
                pendingFallbackDuration = duration
                showRetryDialog(error: error)
            } else {
                showError(message: error.localizedDescription)
            }
        }
    }

    /// Show dialog offering to retry transcription via HTTP
    private func showRetryDialog(error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Ошибка соединения"
        alert.informativeText = "Запись сохранена локально. Отправить повторно?"
        alert.addButton(withTitle: "Отправить")
        alert.addButton(withTitle: "Отмена")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            retryTranscription()
        } else {
            // Clean up backup
            if let backup = backupFileURL {
                localRecorder.deleteBackup(backup)
            }
            backupFileURL = nil
            currentTranscript = ""
            interimTranscript = ""
        }
    }

    /// Retry transcription using HTTP API
    private func retryTranscription() {
        guard let backupURL = backupFileURL else { return }

        isRetrying = true

        Task {
            do {
                let result = try await deepgramHTTP.transcribe(fileURL: backupURL)

                await MainActor.run {
                    isRetrying = false

                    // Clean text if enabled
                    var finalText = result.text
                    if textCleaningEnabled && !finalText.isEmpty {
                        finalText = textCleaner.clean(finalText)
                    }

                    // Process the transcript
                    if !finalText.isEmpty {
                        let entry = TranscriptEntry(
                            text: finalText,
                            duration: pendingFallbackDuration
                        )

                        // Add to history
                        history.insert(entry, at: 0)
                        storage.addToHistory(entry)

                        // Copy to clipboard
                        pasteService.copyToClipboard(finalText)

                        // Play success sound
                        soundService.play(.success)
                    }

                    // Clean up
                    localRecorder.deleteBackup(backupURL)
                    backupFileURL = nil
                    currentTranscript = ""
                    interimTranscript = ""
                }
            } catch {
                await MainActor.run {
                    isRetrying = false
                    soundService.play(.error)
                    showError(message: "Повторная отправка не удалась: \(error.localizedDescription)")

                    // Keep backup for potential manual retry
                }
            }
        }
    }

    nonisolated func deepgramServiceDidConnect(_ service: DeepgramService) {
        Task { @MainActor in
            isConnecting = false
            isConnected = true
            isRecording = true
            recordingStartTime = Date()

            // Play start sound
            soundService.play(.start)

            // Start local backup recording
            backupFileURL = localRecorder.startRecording()

            // Show floating window if enabled
            if showFloatingWindow {
                floatingWindowController.show(
                    appState: self,
                    audioLevel: Binding(
                        get: { self.currentAudioLevel },
                        set: { self.currentAudioLevel = $0 }
                    )
                )
            }

            // Start audio recording
            do {
                try audioService.startRecording()
            } catch {
                showError(message: error.localizedDescription)
                service.disconnect()
                isRecording = false
                isConnected = false
                floatingWindowController.hide()
            }
        }
    }

    nonisolated func deepgramServiceDidDisconnect(_ service: DeepgramService) {
        Task { @MainActor in
            isConnected = false
            if isRecording {
                stopRecording()
            }
        }
    }
}
