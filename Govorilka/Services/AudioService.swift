import AppKit
import AVFoundation
import Combine
import Foundation

/// Protocol for receiving audio data chunks
protocol AudioServiceDelegate: AnyObject {
    func audioService(_ service: AudioService, didReceiveAudioData data: Data)
    func audioService(_ service: AudioService, didFailWithError error: Error)
    func audioService(_ service: AudioService, didUpdateAudioLevel level: Float)
}

/// Error types for AudioService
enum AudioServiceError: LocalizedError {
    case microphonePermissionDenied
    case engineStartFailed
    case formatConversionFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Доступ к микрофону запрещён. Разрешите доступ в Системных настройках."
        case .engineStartFailed:
            return "Не удалось запустить аудио-движок."
        case .formatConversionFailed:
            return "Ошибка конвертации аудио формата."
        }
    }
}

/// Service for capturing audio from microphone using AVAudioEngine
final class AudioService {
    weak var delegate: AudioServiceDelegate?

    private let audioEngine = AVAudioEngine()
    private var isRecording = false
    private var recordingStartTime: Date?

    // Target format for Deepgram: PCM 16-bit, 16kHz, mono
    private let targetSampleRate: Double = 16000
    private let targetChannels: AVAudioChannelCount = 1

    // Audio level tracking
    private var audioLevelSmoother: Float = 0.0
    private let smoothingFactor: Float = 0.3

    // MARK: - Public Methods

    /// Check and request microphone permission
    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    /// Open Microphone preferences in System Settings
    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Start recording audio
    func startRecording() throws {
        guard !isRecording else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create converter to target format
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: true
        ) else {
            throw AudioServiceError.formatConversionFailed
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioServiceError.formatConversionFailed
        }

        // Install tap on input node
        let bufferSize: AVAudioFrameCount = 1024

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
        }

        // Prepare and start engine
        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            recordingStartTime = Date()
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioServiceError.engineStartFailed
        }
    }

    /// Stop recording and return duration
    @discardableResult
    func stopRecording() -> TimeInterval {
        guard isRecording else { return 0 }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false

        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        recordingStartTime = nil

        return duration
    }

    /// Current recording status
    var recording: Bool {
        isRecording
    }

    /// Current recording duration
    var currentDuration: TimeInterval {
        recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
    }

    // MARK: - Private Methods

    private func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) {
        // Calculate audio level from input buffer
        let audioLevel = calculateAudioLevel(buffer)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Apply smoothing
            self.audioLevelSmoother = self.audioLevelSmoother * (1 - self.smoothingFactor) + audioLevel * self.smoothingFactor
            self.delegate?.audioService(self, didUpdateAudioLevel: self.audioLevelSmoother)
        }

        // Calculate output buffer size
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            return
        }

        // Convert buffer
        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            delegate?.audioService(self, didFailWithError: error)
            return
        }

        // Extract PCM data
        guard let channelData = outputBuffer.int16ChannelData else { return }

        let frameLength = Int(outputBuffer.frameLength)
        let data = Data(bytes: channelData[0], count: frameLength * MemoryLayout<Int16>.size)

        delegate?.audioService(self, didReceiveAudioData: data)
    }

    /// Calculate RMS audio level from buffer (0.0 to 1.0)
    private func calculateAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        let data = channelData[0]

        for i in 0..<frameLength {
            let sample = data[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))

        // Convert to 0-1 range with some scaling for better visualization
        // Typical speech is around -20dB to -6dB
        let db = 20 * log10(max(rms, 0.000001))
        let normalizedDb = (db + 50) / 50 // Normalize -50dB to 0dB range
        return max(0, min(1, normalizedDb))
    }
}
