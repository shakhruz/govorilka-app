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
                // Custom icon from Assets
                Image(appState.isRecording ? "MenuBarIconRecording" : "MenuBarIcon")
                    .renderingMode(.template)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
