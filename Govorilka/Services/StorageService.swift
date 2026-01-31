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
        static let showFloatingWindow = "show_floating_window"
        static let hotkeyMode = "hotkey_mode"
        static let maxHistoryCount = "max_history_count"
        static let onboardingCompleted = "onboarding_completed"
        static let accessibilityOnboardingSkipped = "accessibility_onboarding_skipped"
        // Pro mode
        static let proModeEnabled = "pro_mode_enabled"
        static let proExportFolderBookmark = "pro_export_folder_bookmark"
        // Text cleaning
        static let textCleaningEnabled = "text_cleaning_enabled"
        // Sound feedback
        static let soundsEnabled = "sounds_enabled"
    }

    // MARK: - API Key (stored in Keychain for security)

    private let keychain = KeychainService.shared

    var apiKey: String? {
        get {
            // First check Keychain
            if let key = keychain.loadApiKey() {
                return key
            }
            // Fallback: check UserDefaults for migration
            return defaults.string(forKey: Keys.apiKey)
        }
        set {
            if let key = newValue, !key.isEmpty {
                do {
                    try keychain.saveApiKey(key)
                    // Remove from UserDefaults after successful Keychain save
                    defaults.removeObject(forKey: Keys.apiKey)
                } catch {
                    print("[StorageService] Failed to save API key to Keychain: \(error)")
                    // Fallback to UserDefaults (not recommended but prevents data loss)
                    defaults.set(newValue, forKey: Keys.apiKey)
                }
            } else {
                keychain.deleteApiKey()
                defaults.removeObject(forKey: Keys.apiKey)
            }
        }
    }

    var hasApiKey: Bool {
        guard let key = apiKey else { return false }
        return !key.isEmpty
    }

    /// Migrate API key from UserDefaults to Keychain (call on app launch)
    func migrateApiKeyToKeychain() {
        // Check if there's a key in UserDefaults that needs migration
        guard let oldKey = defaults.string(forKey: Keys.apiKey), !oldKey.isEmpty else {
            return
        }

        // Check if already in Keychain
        if keychain.loadApiKey() != nil {
            // Already migrated, just clean up UserDefaults
            defaults.removeObject(forKey: Keys.apiKey)
            print("[StorageService] API key already in Keychain, cleaned UserDefaults")
            return
        }

        // Migrate to Keychain
        do {
            try keychain.saveApiKey(oldKey)
            defaults.removeObject(forKey: Keys.apiKey)
            print("[StorageService] API key migrated to Keychain successfully")
        } catch {
            print("[StorageService] Failed to migrate API key to Keychain: \(error)")
        }
    }

    // MARK: - LLM API Key (stored in Keychain for security)

    var llmApiKey: String? {
        get {
            return keychain.loadLLMApiKey()
        }
        set {
            if let key = newValue, !key.isEmpty {
                do {
                    try keychain.saveLLMApiKey(key)
                } catch {
                    print("[StorageService] Failed to save LLM API key to Keychain: \(error)")
                }
            } else {
                keychain.deleteLLMApiKey()
            }
        }
    }

    var hasLLMApiKey: Bool {
        guard let key = llmApiKey else { return false }
        return !key.isEmpty
    }

    // MARK: - Settings

    var autoPasteEnabled: Bool {
        get { defaults.object(forKey: Keys.autoPasteEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.autoPasteEnabled) }
    }

    var showFloatingWindow: Bool {
        get { defaults.object(forKey: Keys.showFloatingWindow) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.showFloatingWindow) }
    }

    var hotkeyMode: HotkeyMode {
        get {
            guard let rawValue = defaults.string(forKey: Keys.hotkeyMode),
                  let mode = HotkeyMode(rawValue: rawValue) else {
                return .optionSpace
            }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.hotkeyMode) }
    }

    var maxHistoryCount: Int {
        get { defaults.object(forKey: Keys.maxHistoryCount) as? Int ?? 50 }
        set { defaults.set(newValue, forKey: Keys.maxHistoryCount) }
    }

    var onboardingCompleted: Bool {
        get { defaults.bool(forKey: Keys.onboardingCompleted) }
        set { defaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }

    var accessibilityOnboardingSkipped: Bool {
        get { defaults.bool(forKey: Keys.accessibilityOnboardingSkipped) }
        set { defaults.set(newValue, forKey: Keys.accessibilityOnboardingSkipped) }
    }

    // MARK: - Pro Mode

    var proModeEnabled: Bool {
        get { defaults.bool(forKey: Keys.proModeEnabled) }
        set { defaults.set(newValue, forKey: Keys.proModeEnabled) }
    }

    var proExportFolderBookmark: Data? {
        get { defaults.data(forKey: Keys.proExportFolderBookmark) }
        set { defaults.set(newValue, forKey: Keys.proExportFolderBookmark) }
    }

    // MARK: - Text Cleaning

    var textCleaningEnabled: Bool {
        get { defaults.object(forKey: Keys.textCleaningEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.textCleaningEnabled) }
    }

    // MARK: - Sound Feedback

    var soundsEnabled: Bool {
        get { defaults.object(forKey: Keys.soundsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.soundsEnabled) }
    }

    /// Save export folder as security-scoped bookmark
    func saveExportFolder(_ url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            proExportFolderBookmark = bookmark
            print("[StorageService] Export folder saved: \(url.path)")
        } catch {
            print("[StorageService] Failed to save export folder bookmark: \(error)")
        }
    }

    /// Resolve export folder from security-scoped bookmark
    func resolveExportFolder() -> URL? {
        guard let bookmark = proExportFolderBookmark else { return nil }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Re-save the bookmark if it's stale
                saveExportFolder(url)
            }

            // Start accessing the security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                return url
            } else {
                print("[StorageService] Failed to access security-scoped resource")
                return nil
            }
        } catch {
            print("[StorageService] Failed to resolve export folder bookmark: \(error)")
            return nil
        }
    }

    /// Stop accessing security-scoped export folder
    func stopAccessingExportFolder(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
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
        defaults.removeObject(forKey: Keys.showFloatingWindow)
        defaults.removeObject(forKey: Keys.hotkeyMode)
        defaults.removeObject(forKey: Keys.maxHistoryCount)
        defaults.removeObject(forKey: Keys.onboardingCompleted)
        defaults.removeObject(forKey: Keys.accessibilityOnboardingSkipped)
        defaults.removeObject(forKey: Keys.proModeEnabled)
        defaults.removeObject(forKey: Keys.proExportFolderBookmark)
        defaults.removeObject(forKey: Keys.textCleaningEnabled)
        defaults.removeObject(forKey: Keys.soundsEnabled)
    }
}
