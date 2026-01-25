// Filler words and patterns to remove (Russian)
const FILLER_PATTERNS: RegExp[] = [
  /\b(ну|эм|эээ|ааа|ммм)\b/gi,
  /\b(типа|как бы|в общем|короче|значит)\b/gi,
  /\b(это самое|так сказать|в принципе)\b/gi,
  /\b(вот|ну вот|ну типа)\b/gi,
];

// Clean up extra spaces and punctuation
const CLEANUP_PATTERNS: [RegExp, string][] = [
  [/\s{2,}/g, ' '],           // Multiple spaces → single
  [/\s+([.,!?;:])/g, '$1'],    // Space before punctuation
  [/^\s+/gm, ''],              // Leading spaces on lines
  [/\s+$/gm, ''],              // Trailing spaces on lines
];

class TextCleanerServiceClass {
  clean(text: string): string {
    let result = text;

    // Remove filler words
    for (const pattern of FILLER_PATTERNS) {
      result = result.replace(pattern, '');
    }

    // Clean up formatting
    for (const [pattern, replacement] of CLEANUP_PATTERNS) {
      result = result.replace(pattern, replacement);
    }

    // Capitalize first letter after period
    result = result.replace(/\.\s+([a-zа-яё])/g, (_, char) => `. ${char.toUpperCase()}`);

    // Capitalize first letter of text
    if (result.length > 0) {
      result = result.charAt(0).toUpperCase() + result.slice(1);
    }

    return result.trim();
  }
}

export const TextCleanerService = new TextCleanerServiceClass();
