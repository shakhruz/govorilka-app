import Foundation

/// Service for cleaning transcribed text from filler words (слова-паразиты)
final class TextCleanerService {
    static let shared = TextCleanerService()

    /// Patterns for filler words removal (regex pattern, replacement)
    private let fillerPatterns: [(regex: NSRegularExpression, replacement: String)]

    private init() {
        // Define patterns for Russian filler words
        let patterns: [(String, String)] = [
            // Междометия и звуки (отдельно стоящие)
            (#"\b[эе]+\b,?\s*"#, ""),           // э, ээ, эээ
            (#"\b[мm]+\b,?\s*"#, ""),            // м, мм, ммм
            (#"\bугу\b,?\s*"#, ""),
            (#"\bага\b,?\s*"#, ""),

            // Вводные слова (более длинные паттерны сначала)
            (#"\bэто самое\b,?\s*"#, ""),
            (#"\bтак сказать\b,?\s*"#, ""),
            (#"\bв общем-то\b,?\s*"#, ""),
            (#"\bв общем\b,?\s*"#, ""),
            (#"\bв принципе\b,?\s*"#, ""),
            (#"\bну вот\b,?\s*"#, ""),
            (#"\bкак бы\b,?\s*"#, ""),
            (#"\bну\b,?\s*"#, ""),
            (#"\bвот\b,?\s*"#, ""),
            (#"\bтипа\b,?\s*"#, ""),
            (#"\bтипо\b,?\s*"#, ""),
            (#"\bкороче\b,?\s*"#, ""),
            (#"\bзначит\b,?\s*"#, ""),
            (#"\bсобственно\b,?\s*"#, ""),
            (#"\bслушай\b,?\s*"#, ""),
            (#"\bсмотри\b,?\s*"#, ""),
        ]

        // Compile regex patterns
        fillerPatterns = patterns.compactMap { pattern, replacement in
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            ) else {
                print("[TextCleanerService] Failed to compile pattern: \(pattern)")
                return nil
            }
            return (regex, replacement)
        }

        print("[TextCleanerService] Initialized with \(fillerPatterns.count) patterns")
    }

    /// Clean text by removing filler words
    /// - Parameter text: Original transcribed text
    /// - Returns: Cleaned text
    func clean(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = text

        // Apply all filler patterns
        for (regex, replacement) in fillerPatterns {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: replacement
            )
        }

        // Normalize whitespace (collapse multiple spaces)
        result = result.replacingOccurrences(
            of: #"\s{2,}"#,
            with: " ",
            options: .regularExpression
        )

        // Trim leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespaces)

        // Capitalize first letter if text starts with lowercase
        if let first = result.first, first.isLowercase {
            result = first.uppercased() + result.dropFirst()
        }

        return result
    }
}
