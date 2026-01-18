import SwiftUI

/// Main popover content for menu bar
struct MenuBarView: View {
    @ObservedObject var appState: AppState

    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Recording section (always visible)
            RecordingView(appState: appState)
                .padding()

            Divider()

            // Tab selection
            Picker("", selection: $selectedTab) {
                Text("История").tag(0)
                Text("Настройки").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Tab content
            Group {
                if selectedTab == 0 {
                    HistoryView(appState: appState)
                } else {
                    SettingsView(appState: appState)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Говорилка v1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Выход") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 320, height: 480)
        .alert("Ошибка", isPresented: $appState.showError) {
            Button("OK") {
                appState.showError = false
            }
        } message: {
            Text(appState.errorMessage ?? "Неизвестная ошибка")
        }
    }
}

#Preview {
    MenuBarView(appState: AppState())
}
