import Foundation

/// Service for fallback transcription via HTTP when WebSocket fails
/// Uses Deepgram's batch API to transcribe pre-recorded audio files
final class DeepgramHTTPService {
    static let shared = DeepgramHTTPService()

    private init() {}

    // MARK: - Types

    enum TranscriptionError: LocalizedError {
        case noApiKey
        case fileNotFound
        case uploadFailed
        case invalidResponse
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .noApiKey:
                return "API ключ Deepgram не настроен"
            case .fileNotFound:
                return "Файл записи не найден"
            case .uploadFailed:
                return "Не удалось загрузить файл"
            case .invalidResponse:
                return "Некорректный ответ сервера"
            case .serverError(let message):
                return "Ошибка сервера: \(message)"
            }
        }
    }

    struct TranscriptionResult {
        let text: String
        let confidence: Double?
    }

    // MARK: - Properties

    private let storage = StorageService.shared

    // Deepgram API configuration
    private let baseURL = "https://api.deepgram.com/v1/listen"
    private let queryParams = [
        "language": "ru",
        "model": "nova-2",
        "punctuate": "true",
        "smart_format": "true"
    ]

    // MARK: - Public Methods

    /// Transcribe a local audio file via HTTP API
    /// - Parameter fileURL: URL of the audio file to transcribe (WAV format)
    /// - Returns: Transcription result
    func transcribe(fileURL: URL) async throws -> TranscriptionResult {
        guard let apiKey = storage.apiKey, !apiKey.isEmpty else {
            throw TranscriptionError.noApiKey
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw TranscriptionError.fileNotFound
        }

        // Build URL with query parameters
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents.url else {
            throw TranscriptionError.uploadFailed
        }

        // Read audio file
        let audioData = try Data(contentsOf: fileURL)

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData

        print("[DeepgramHTTP] Sending \(audioData.count) bytes to API...")

        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }

        // Check response status
        guard httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                print("[DeepgramHTTP] Error response: \(errorText)")
                throw TranscriptionError.serverError(errorText)
            }
            throw TranscriptionError.serverError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response
        let result = try parseResponse(data)
        print("[DeepgramHTTP] Transcription successful: \"\(result.text.prefix(50))...\"")
        return result
    }

    // MARK: - Private Methods

    private func parseResponse(_ data: Data) throws -> TranscriptionResult {
        let response = try JSONDecoder().decode(HTTPResponse.self, from: data)

        // Extract transcript from first channel's first alternative
        guard let channel = response.results?.channels.first,
              let alternative = channel.alternatives.first else {
            throw TranscriptionError.invalidResponse
        }

        return TranscriptionResult(
            text: alternative.transcript,
            confidence: alternative.confidence
        )
    }
}

// MARK: - Response Models

private struct HTTPResponse: Codable {
    let results: ResultsContainer?
}

private struct ResultsContainer: Codable {
    let channels: [ChannelResult]
}

private struct ChannelResult: Codable {
    let alternatives: [Alternative]
}

private struct Alternative: Codable {
    let transcript: String
    let confidence: Double?
}
