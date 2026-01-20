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

    // Recording state
    private var recordingStartTime: Date?

    // MARK: - Initialization

    init() {
        // Load saved settings
        apiKey = storage.apiKey ?? ""
        autoPasteEnabled = storage.autoPasteEnabled
        showFloatingWindow = storage.showFloatingWindow
        hotkeyMode = storage.hotkeyMode
        history = storage.loadHistory()
        hasAccessibilityPermission = pasteService.hasAccessibilityPermission()

        // Set up delegates
        audioService.delegate = self
        deepgramService.delegate = self

        // Set up keyboard shortcut for standard modes
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                // Only trigger if using optionSpace or custom mode
                if self.hotkeyMode == .optionSpace || self.hotkeyMode == .custom {
                    self.toggleRecording()
                }
            }
        }

        // Set up hotkey service for special modes
        hotkeyService.onHotkeyTriggered = { [weak self] in
            Task { @MainActor in
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

    /// Toggle recording on/off
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    /// Start recording
    func startRecording() {
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

            // Connect to Deepgram
            isConnecting = true

            do {
                try deepgramService.connect()
            } catch {
                isConnecting = false
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
        let finalText = currentTranscript.isEmpty ? interimTranscript : currentTranscript

        // Disconnect first (this will close the WebSocket)
        deepgramService.disconnect()

        // Reset state
        isRecording = false
        isConnected = false
        currentTranscript = ""
        interimTranscript = ""
        currentAudioLevel = 0.0
        recordingStartTime = nil

        // Process the transcript after a small delay to let UI update
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
                    // Longer delay to ensure floating window is fully hidden and target app regains focus
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        print("[AppState] Triggering pasteAtCursor")
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
