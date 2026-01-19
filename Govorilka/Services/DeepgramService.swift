import Foundation

/// Protocol for receiving transcription updates
protocol DeepgramServiceDelegate: AnyObject {
    func deepgramService(_ service: DeepgramService, didReceiveTranscript text: String, isFinal: Bool)
    func deepgramService(_ service: DeepgramService, didFailWithError error: Error)
    func deepgramServiceDidConnect(_ service: DeepgramService)
    func deepgramServiceDidDisconnect(_ service: DeepgramService)
}

/// Error types for DeepgramService
enum DeepgramServiceError: LocalizedError {
    case noApiKey
    case connectionFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "API ключ Deepgram не настроен. Добавьте ключ в настройках."
        case .connectionFailed:
            return "Не удалось подключиться к Deepgram."
        case .invalidResponse:
            return "Получен некорректный ответ от сервера."
        }
    }
}

/// Service for streaming audio to Deepgram API via WebSocket
final class DeepgramService: NSObject {
    weak var delegate: DeepgramServiceDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected = false

    private let storage = StorageService.shared

    // Deepgram API configuration
    private let baseURL = "wss://api.deepgram.com/v1/listen"
    private let queryParams = [
        "language": "ru",  // Russian language
        "model": "nova-2",
        "punctuate": "true",
        "smart_format": "true",
        "interim_results": "true",
        "encoding": "linear16",
        "sample_rate": "16000",
        "channels": "1"
    ]

    // MARK: - Public Methods

    /// Connect to Deepgram WebSocket
    func connect() throws {
        guard let apiKey = storage.apiKey, !apiKey.isEmpty else {
            throw DeepgramServiceError.noApiKey
        }

        // Build URL with query parameters
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents.url else {
            throw DeepgramServiceError.connectionFailed
        }

        // Create request with auth header
        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        // Create WebSocket task
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        webSocketTask = urlSession?.webSocketTask(with: request)

        // Start connection
        webSocketTask?.resume()
        receiveMessage()
    }

    /// Disconnect from Deepgram
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        isConnected = false
    }

    /// Send audio data to Deepgram
    func sendAudio(_ data: Data) {
        guard isConnected else { return }

        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    /// Signal end of audio stream
    func finishStream() {
        guard isConnected else { return }

        // Send close stream message (empty JSON)
        let closeMessage = URLSessionWebSocketTask.Message.string("{\"type\": \"CloseStream\"}")
        webSocketTask?.send(closeMessage) { _ in }
    }

    /// Connection status
    var connected: Bool {
        isConnected
    }

    // MARK: - Private Methods

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleMessage(message)
                // Continue receiving
                self.receiveMessage()

            case .failure(let error):
                DispatchQueue.main.async {
                    self.delegate?.deepgramService(self, didFailWithError: error)
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseResponse(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseResponse(text)
            }
        @unknown default:
            break
        }
    }

    private func parseResponse(_ json: String) {
        guard let data = json.data(using: .utf8) else { return }

        do {
            let response = try JSONDecoder().decode(DeepgramResponse.self, from: data)

            // Extract transcript from first alternative
            guard let channel = response.channel,
                  let alternative = channel.alternatives.first else {
                return
            }

            let transcript = alternative.transcript
            let isFinal = response.isFinal ?? false

            // Only emit non-empty transcripts
            guard !transcript.isEmpty else { return }

            DispatchQueue.main.async {
                self.delegate?.deepgramService(self, didReceiveTranscript: transcript, isFinal: isFinal)
            }

        } catch {
            // Ignore parse errors for non-transcript messages (metadata, etc.)
            print("Parse error (might be metadata): \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension DeepgramService: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        isConnected = true
        DispatchQueue.main.async {
            self.delegate?.deepgramServiceDidConnect(self)
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        isConnected = false
        DispatchQueue.main.async {
            self.delegate?.deepgramServiceDidDisconnect(self)
        }
    }
}

// MARK: - Response Models

private struct DeepgramResponse: Codable {
    let channel: ChannelResult?
    let isFinal: Bool?

    enum CodingKeys: String, CodingKey {
        case channel
        case isFinal = "is_final"
    }
}

private struct ChannelResult: Codable {
    let alternatives: [Alternative]
}

private struct Alternative: Codable {
    let transcript: String
    let confidence: Double?
}
