import KeyboardShortcuts
import SwiftUI

/// Settings view
struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var apiKeyInput = ""
    @State private var showApiKey = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // API Key section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Deepgram API Key", systemImage: "key.fill")
                            .font(.headline)

                        HStack {
                            if showApiKey {
                                TextField("Введите API ключ", text: $apiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("Введите API ключ", text: $apiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(action: { showApiKey.toggle() }) {
                                Image(systemName: showApiKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.plain)
                        }

                        HStack {
                            Button("Сохранить") {
                                appState.saveApiKey(apiKeyInput)
                            }
                            .disabled(apiKeyInput.isEmpty)

                            if !appState.apiKey.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Сохранён")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Link(destination: URL(string: "https://console.deepgram.com/signup")!) {
                            Label("Получить бесплатный ключ", systemImage: "arrow.up.right.square")
                                .font(.caption)
                        }

                        Text("$200 бесплатных кредитов при регистрации")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Hotkey section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Горячая клавиша", systemImage: "keyboard")
                            .font(.headline)

                        HStack {
                            Text("Старт/Стоп записи:")
                            Spacer()
                            KeyboardShortcuts.Recorder(for: .toggleRecording)
                        }

                        Text("Нажмите для изменения")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Auto-paste section
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Автовставка", systemImage: "doc.on.clipboard")
                            .font(.headline)

                        Toggle("Автоматически вставлять текст", isOn: Binding(
                            get: { appState.autoPasteEnabled },
                            set: { appState.saveAutoPaste($0) }
                        ))

                        Text("После транскрибации текст будет вставлен в активное окно")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Accessibility permission
                        if appState.autoPasteEnabled {
                            Divider()

                            HStack {
                                if appState.hasAccessibilityPermission {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Доступ разрешён")
                                        .font(.caption)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Требуется доступ")
                                        .font(.caption)
                                }

                                Spacer()

                                Button("Настроить") {
                                    appState.requestAccessibility()
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }

                            Text("Для автовставки нужен доступ Accessibility в Системных настройках")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // About section
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("О приложении", systemImage: "info.circle")
                            .font(.headline)

                        Text("Говорилка — бесплатная утилита для транскрибации голоса в текст.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Link("Deepgram", destination: URL(string: "https://deepgram.com")!)
                            Text("•")
                                .foregroundColor(.secondary)
                            Link("GitHub", destination: URL(string: "https://github.com/skylineyoga/govorilka")!)
                        }
                        .font(.caption)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            apiKeyInput = appState.apiKey
            appState.refreshAccessibilityStatus()
        }
    }
}

#Preview {
    SettingsView(appState: AppState())
        .frame(width: 300, height: 500)
}
