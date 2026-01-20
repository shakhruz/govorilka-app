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
    let proReviewController = ProReviewWindowController()
    private var pendingScreenshot: NSImage?
    private var pendingDuration: TimeInterval = 0
    private var isProRecording = false  // Flag: current recording is Pro (with screenshot)
    private let screenshotService = ScreenshotService.shared

    // Accessibility onboarding
    let onboardingWindowController = OnboardingWindowController()

    // Flag to suppress errors during intentional disconnect
    private var isDisconnecting = false

    // MARK: - Services

    private let audioService = AudioService()
    private let deepgramService = DeepgramService()
    private let pasteService = PasteService.shared
    private let storage = StorageService.shared
    private let hotkeyService = HotkeyService.shared
    private let textCleaner = TextCleanerService.shared

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
        history = storage.loadHistory()
        hasAccessibilityPermission = pasteService.hasAccessibilityPermission()

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
                showError(message: "Доступ к микрофону запрещён")
                return
            }

            // Capture screenshot BEFORE recording if Pro mode
            if withScreenshot {
                pendingScreenshot = await screenshotService.captureScreen()
                print("[AppState] Pro recording: screenshot captured")
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
        guard isRecording else { return }

        // Set flag to suppress disconnect errors
        isDisconnecting = true

        // Hide floating window
        floatingWindowController.hide()

        // Stop audio capture
        let duration = audioService.stopRecording()

        // Save final transcript if we have one
        var finalText = currentTranscript.isEmpty ? interimTranscript : currentTranscript

        // Clean text from filler words if enabled
        if textCleaningEnabled && !finalText.isEmpty {
            finalText = textCleaner.clean(finalText)
        }

        // Disconnect first (this will close the WebSocket)
        deepgramService.disconnect()

        // Reset state
        isRecording = false
        isConnected = false
        currentTranscript = ""
        interimTranscript = ""
        currentAudioLevel = 0.0
        recordingStartTime = nil

        // Pro mode: show review dialog
        if isProRecording, let screenshot = pendingScreenshot, !finalText.isEmpty {
            pendingDuration = duration
            proReviewController.show(
                screenshot: screenshot,
                transcript: finalText,
                duration: duration,
                onSave: { [weak self] data in
                    self?.handleProSave(data: data)
                },
                onCancel: { [weak self] in
                    self?.handleProCancel()
                }
            )
            pendingScreenshot = nil
            isProRecording = false

            // Reset disconnect flag after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isDisconnecting = false
            }
            return
        }

        // Clear pending screenshot if any
        pendingScreenshot = nil
        isProRecording = false

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

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        let frontAppNow = NSWorkspace.shared.frontmostApplication
                        print("[AppState] 📋 After delay - frontmost app: \(frontAppNow?.localizedName ?? "unknown")")
                        print("[AppState] 📋 Triggering pasteAtCursor with text: \"\(finalText.prefix(50))...\"")
                        self?.pasteService.pasteAtCursor(finalText, restoreClipboard: true)
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
        // Delete screenshot if exists
        if let filename = entry.screenshotFilename {
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

    /// Save export folder
    func saveExportFolder(_ url: URL) {
        storage.saveExportFolder(url)
    }

    /// Request accessibility permission
    func requestAccessibility() {
        pasteService.requestAccessibilityPermission()
        // Check again after a delay (user might grant permission)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.hasAccessibilityPermission = self?.pasteService.hasAccessibilityPermission() ?? false
        }
    }

    /// Refresh accessibility permission status
    func refreshAccessibilityStatus() {
        hasAccessibilityPermission = pasteService.hasAccessibilityPermission()
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
            showError(message: error.localizedDescription)
            stopRecording()
        }
    }

    nonisolated func deepgramServiceDidConnect(_ service: DeepgramService) {
        Task { @MainActor in
            isConnecting = false
            isConnected = true
            isRecording = true
            recordingStartTime = Date()

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
