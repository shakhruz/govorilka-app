import Foundation

/// Service for local audio backup during recording
/// Allows fallback transcription via HTTP if WebSocket fails
final class LocalRecorderService {
    static let shared = LocalRecorderService()

    private init() {}

    // MARK: - Properties

    private var fileHandle: FileHandle?
    private var tempFileURL: URL?
    private var bytesWritten: UInt32 = 0
    private var isRecording = false

    // Audio format constants (matches AudioService output)
    private let sampleRate: UInt32 = 16000
    private let bitsPerSample: UInt16 = 16
    private let numChannels: UInt16 = 1

    // MARK: - Public Methods

    /// Start recording to a temporary WAV file
    /// - Returns: URL of the temporary file being recorded to
    func startRecording() -> URL? {
        guard !isRecording else {
            print("[LocalRecorder] Already recording")
            return tempFileURL
        }

        // Create temp file in app's temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "govorilka_backup_\(UUID().uuidString).wav"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            // Create empty file with placeholder header
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            let handle = try FileHandle(forWritingTo: fileURL)

            // Write placeholder WAV header (will be updated on finish)
            let headerData = createWAVHeader(dataSize: 0)
            handle.write(headerData)

            self.fileHandle = handle
            self.tempFileURL = fileURL
            self.bytesWritten = 0
            self.isRecording = true

            print("[LocalRecorder] Started recording to: \(fileURL.path)")
            return fileURL
        } catch {
            print("[LocalRecorder] Failed to start recording: \(error)")
            return nil
        }
    }

    /// Append audio data chunk to the recording
    /// - Parameter data: Raw PCM audio data (16-bit, 16kHz, mono)
    func appendAudio(_ data: Data) {
        guard isRecording, let handle = fileHandle else { return }

        handle.write(data)
        bytesWritten += UInt32(data.count)
    }

    /// Finish recording and finalize the WAV file
    /// - Returns: URL of the completed WAV file, or nil if recording failed
    func finishRecording() -> URL? {
        guard isRecording, let handle = fileHandle, let fileURL = tempFileURL else {
            print("[LocalRecorder] Not recording or invalid state")
            return nil
        }

        isRecording = false

        // Update WAV header with correct file size
        do {
            // Seek to beginning and rewrite header
            try handle.seek(toOffset: 0)
            let headerData = createWAVHeader(dataSize: bytesWritten)
            handle.write(headerData)

            // Close file
            try handle.close()

            print("[LocalRecorder] Finished recording: \(bytesWritten) bytes written")

            let result = fileURL
            self.fileHandle = nil
            self.tempFileURL = nil
            self.bytesWritten = 0

            return result
        } catch {
            print("[LocalRecorder] Failed to finalize recording: \(error)")
            cleanup()
            return nil
        }
    }

    /// Cancel recording and delete the temp file
    func cancelRecording() {
        guard isRecording else { return }

        isRecording = false
        cleanup()
        print("[LocalRecorder] Recording cancelled")
    }

    /// Check if currently recording
    var recording: Bool {
        return isRecording
    }

    /// Get current temp file URL
    var currentFileURL: URL? {
        return tempFileURL
    }

    /// Delete a backup file that's no longer needed
    func deleteBackup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        print("[LocalRecorder] Deleted backup: \(url.lastPathComponent)")
    }

    // MARK: - Private Methods

    private func cleanup() {
        if let handle = fileHandle {
            try? handle.close()
        }
        if let url = tempFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        fileHandle = nil
        tempFileURL = nil
        bytesWritten = 0
    }

    /// Create a WAV file header
    /// - Parameter dataSize: Size of the audio data in bytes
    /// - Returns: Complete 44-byte WAV header
    private func createWAVHeader(dataSize: UInt32) -> Data {
        var header = Data(capacity: 44)

        // RIFF chunk descriptor
        header.append(contentsOf: "RIFF".utf8)                          // ChunkID
        let fileSize = dataSize + 36                                     // ChunkSize
        header.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        header.append(contentsOf: "WAVE".utf8)                          // Format

        // fmt sub-chunk
        header.append(contentsOf: "fmt ".utf8)                          // Subchunk1ID
        let subchunk1Size: UInt32 = 16                                  // Subchunk1Size (PCM)
        header.append(contentsOf: withUnsafeBytes(of: subchunk1Size.littleEndian) { Array($0) })
        let audioFormat: UInt16 = 1                                     // AudioFormat (PCM)
        header.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })  // NumChannels
        header.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian) { Array($0) })   // SampleRate
        let byteRate = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample) / 8  // ByteRate
        header.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = numChannels * bitsPerSample / 8                // BlockAlign
        header.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        header.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) }) // BitsPerSample

        // data sub-chunk
        header.append(contentsOf: "data".utf8)                          // Subchunk2ID
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })  // Subchunk2Size

        return header
    }
}
