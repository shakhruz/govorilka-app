import AppKit

/// Service for playing system sounds for feedback
final class SoundService {
    static let shared = SoundService()

    private init() {}

    // MARK: - Sound Types

    enum Sound {
        case start      // Recording started
        case stop       // Recording stopped
        case error      // Connection/recording error
        case success    // Text pasted successfully

        var systemName: String {
            switch self {
            case .start: return "Tink"
            case .stop: return "Glass"
            case .error: return "Basso"
            case .success: return "Ping"
            }
        }
    }

    // MARK: - Dependencies

    private let storage = StorageService.shared

    // MARK: - Public Methods

    /// Play a system sound if sounds are enabled
    func play(_ sound: Sound) {
        guard storage.soundsEnabled else { return }
        NSSound(named: NSSound.Name(sound.systemName))?.play()
    }
}
