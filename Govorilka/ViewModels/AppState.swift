import AppKit
import Combine
import Foundation
import KeyboardShortcuts

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

    // Connection status
    @Published var isConnecting = false
    @Published var isConnected = false

    // MARK: - Services

    private let audioService = AudioService()
    private let deepgramService = DeepgramService()
    private let pasteService = PasteService.shared
    private let storage = StorageService.shared

    // Recording state
    private var recordingStartTime: Date?

    // MARK: - Initialization

    init() {
        // Load saved settings
        apiKey = storage.apiKey ?? ""
        autoPasteEnabled = storage.autoPasteEnabled
        history = storage.loadHistory()
        hasAccessibilityPermission = pasteService.hasAccessibilityPermission()

        // Set up delegates
        audioService.delegate = self
        deepgramService.delegate = self

        // Set up keyboard shortcut
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            Task { @MainActor in
                self?.toggleRecording()
            }
        }
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

        // Stop audio capture
        let duration = audioService.stopRecording()

        // Signal end of stream
        deepgramService.finishStream()

        // Save final transcript if we have one
        let finalText = currentTranscript.isEmpty ? interimTranscript : currentTranscript

        if !finalText.isEmpty {
            let entry = TranscriptEntry(
                text: finalText,
                duration: duration
            )

            // Add to history
            history.insert(entry, at: 0)
            storage.addToHistory(entry)

            // Copy to clipboard
            pasteService.copyToClipboard(finalText)

            // Auto-paste if enabled and have permission
            if autoPasteEnabled && hasAccessibilityPermission {
                pasteService.copyAndPaste(finalText)
            }
        }

        // Disconnect
        deepgramService.disconnect()

        // Reset state
        isRecording = false
        isConnected = false
        currentTranscript = ""
        interimTranscript = ""
        recordingStartTime = nil
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

            // Start audio recording
            do {
                try audioService.startRecording()
            } catch {
                showError(message: error.localizedDescription)
                service.disconnect()
                isRecording = false
                isConnected = false
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
