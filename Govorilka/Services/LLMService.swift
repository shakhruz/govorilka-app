import Foundation

/// Service for improving transcription text using LLM (Groq API)
final class LLMService {
    static let shared = LLMService()

    private let storage = StorageService.shared
    private let baseURL = "https://api.groq.com/openai/v1/chat/completions"
    private let model = "llama-3.3-70b-versatile"

    private init() {}

    // MARK: - Public Methods

    /// Improve transcription text using LLM
    /// - Parameter text: Original transcription text
    /// - Returns: Improved text
    /// - Throws: LLMError if request fails
    func improveText(_ text: String) async throws -> String {
        guard let apiKey = storage.llmApiKey, !apiKey.isEmpty else {
            throw LLMError.noApiKey
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }

        let request = try createRequest(text: text, apiKey: apiKey)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw LLMError.invalidApiKey
            } else if httpResponse.statusCode == 429 {
                throw LLMError.rateLimitExceeded
            }
            throw LLMError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(GroqResponse.self, from: data)

        guard let content = result.choices.first?.message.content else {
            throw LLMError.noContent
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private Methods

    private func createRequest(text: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let systemPrompt = """
        Ты - ассистент для улучшения качества транскрипции голосовых сообщений.

        Твоя задача:
        1. Исправить грамматические ошибки
        2. Добавить правильную пунктуацию
        3. Исправить очевидные опечатки и ошибки распознавания
        4. Сохранить смысл и стиль оригинального текста

        Правила:
        - НЕ меняй смысл текста
        - НЕ добавляй новую информацию
        - НЕ удаляй важную информацию
        - Сохраняй язык оригинала (русский или английский)
        - Отвечай ТОЛЬКО улучшенным текстом, без пояснений
        """

        let requestBody = GroqRequest(
            model: model,
            messages: [
                GroqMessage(role: "system", content: systemPrompt),
                GroqMessage(role: "user", content: text)
            ],
            temperature: 0.3,
            max_tokens: 2048
        )

        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }
}

// MARK: - Request/Response Models

private struct GroqRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
    let max_tokens: Int
}

private struct GroqMessage: Codable {
    let role: String
    let content: String
}

private struct GroqResponse: Decodable {
    let choices: [GroqChoice]
}

private struct GroqChoice: Decodable {
    let message: GroqMessage
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case noApiKey
    case invalidURL
    case invalidResponse
    case invalidApiKey
    case rateLimitExceeded
    case httpError(Int)
    case noContent

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "API ключ не настроен"
        case .invalidURL:
            return "Неверный URL API"
        case .invalidResponse:
            return "Неверный ответ от сервера"
        case .invalidApiKey:
            return "Неверный API ключ"
        case .rateLimitExceeded:
            return "Превышен лимит запросов"
        case .httpError(let code):
            return "Ошибка HTTP: \(code)"
        case .noContent:
            return "Пустой ответ от сервера"
        }
    }
}
