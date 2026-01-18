import SwiftUI

@main
struct GovorilkaApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar app
        MenuBarExtra {
            MenuBarView(appState: appState)
        } label: {
            Label {
                Text("Говорилка")
            } icon: {
                Image(systemName: appState.isRecording ? "mic.fill" : "mic")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(appState.isRecording ? .red : .primary)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
