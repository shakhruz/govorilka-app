import SwiftUI

@main
struct GovorilkaApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Migrate API key from UserDefaults to Keychain (one-time migration)
        StorageService.shared.migrateApiKeyToKeychain()
    }

    var body: some Scene {
        // Menu bar app
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Label {
                Text("Говорилка")
            } icon: {
                // Custom colored icon from Assets (not template - shows green/red dot)
                Image(appState.isRecording ? "MenuBarIconRecording" : "MenuBarIcon")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
