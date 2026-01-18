import Foundation

/// Represents a single transcription entry in the history
struct TranscriptEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let timestamp: Date
    let duration: TimeInterval // Recording duration in seconds

    init(id: UUID = UUID(), text: String, timestamp: Date = Date(), duration: TimeInterval = 0) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
    }

    /// Formatted timestamp for display
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm"
            return "Сегодня, \(formatter.string(from: timestamp))"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "HH:mm"
            return "Вчера, \(formatter.string(from: timestamp))"
        } else {
            formatter.dateFormat = "d MMM, HH:mm"
            formatter.locale = Locale(identifier: "ru_RU")
            return formatter.string(from: timestamp)
        }
    }

    /// Formatted duration for display
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds) сек"
        }
    }

    /// Preview of text (first 100 characters)
    var preview: String {
        if text.count <= 100 {
            return text
        }
        return String(text.prefix(100)) + "..."
    }
}

// MARK: - Sample Data for Previews

extension TranscriptEntry {
    static let sample = TranscriptEntry(
        text: "Привет, это тестовая транскрипция для проверки работы приложения Говорилка.",
        duration: 15.5
    )

    static let samples: [TranscriptEntry] = [
        TranscriptEntry(
            text: "Первая тестовая запись с достаточно длинным текстом, чтобы проверить как отображается превью в списке истории.",
            timestamp: Date(),
            duration: 25.0
        ),
        TranscriptEntry(
            text: "Вторая запись покороче.",
            timestamp: Date().addingTimeInterval(-3600),
            duration: 5.0
        ),
        TranscriptEntry(
            text: "This is a test in English to verify that the app handles multiple languages correctly.",
            timestamp: Date().addingTimeInterval(-86400),
            duration: 12.0
        )
    ]
}
