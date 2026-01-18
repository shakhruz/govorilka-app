import Foundation

/// Service for persisting app data using UserDefaults
final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let apiKey = "deepgram_api_key"
        static let history = "transcript_history"
        static let autoPasteEnabled = "auto_paste_enabled"
        static let maxHistoryCount = "max_history_count"
        static let onboardingCompleted = "onboarding_completed"
    }

    // MARK: - API Key

    var apiKey: String? {
        get { defaults.string(forKey: Keys.apiKey) }
        set { defaults.set(newValue, forKey: Keys.apiKey) }
    }

    var hasApiKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    // MARK: - Settings

    var autoPasteEnabled: Bool {
        get { defaults.object(forKey: Keys.autoPasteEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoPasteEnabled) }
    }

    var maxHistoryCount: Int {
        get { defaults.object(forKey: Keys.maxHistoryCount) as? Int ?? 50 }
        set { defaults.set(newValue, forKey: Keys.maxHistoryCount) }
    }

    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }

    // MARK: - History

    func loadHistory() -> [TranscriptEntry] {
        guard let data = defaults.data(forKey: Keys.history) else {
            return []
        }

        do {
            let entries = try JSONDecoder().decode([TranscriptEntry].self, from: data)
            return entries
        } catch {
            print("Failed to decode history: \(error)")
            return []
        }
    }

    func saveHistory(_ entries: [TranscriptEntry]) {
        // Trim to max count
        let trimmedEntries = Array(entries.prefix(maxHistoryCount))

        do {
            let data = try JSONEncoder().encode(trimmedEntries)
            defaults.set(data, forKey: Keys.history)
        } catch {
            print("Failed to encode history: \(error)")
        }
    }

    func addToHistory(_ entry: TranscriptEntry) {
        var history = loadHistory()
        history.insert(entry, at: 0)
        saveHistory(history)
    }

    func removeFromHistory(_ entry: TranscriptEntry) {
        var history = loadHistory()
        history.removeAll { $0.id == entry.id }
        saveHistory(history)
    }

    func clearHistory() {
        defaults.removeObject(forKey: Keys.history)
    }

    // MARK: - Reset

    func resetAllSettings() {
        defaults.removeObject(forKey: Keys.apiKey)
        defaults.removeObject(forKey: Keys.history)
        defaults.removeObject(forKey: Keys.autoPasteEnabled)
        defaults.removeObject(forKey: Keys.maxHistoryCount)
        defaults.removeObject(forKey: Keys.onboardingCompleted)
    }
}
