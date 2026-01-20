import AppKit
import SwiftUI

/// Beautiful simplified settings view with pink theme
struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var apiKeyInput = ""
    @State private var showApiKey = false
    @State private var exportFolderName: String = "Не выбрана"

    // Theme colors
    private let pinkColor = Color(hex: "FF69B4")
    private let lightPink = Color(hex: "FFB6C1")
    private let softPink = Color(hex: "FFF5F8")
    private let textColor = Color(hex: "5D4E6D")

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // API Key section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "key.fill",
                            title: "API Ключ",
                            color: pinkColor
                        )

                        HStack(spacing: 8) {
                            if showApiKey {
                                TextField("Введите API ключ", text: $apiKeyInput)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(softPink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                SecureField("Введите API ключ", text: $apiKeyInput)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(softPink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button(action: { showApiKey.toggle() }) {
                                Image(systemName: showApiKey ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(textColor.opacity(0.5))
                                    .frame(width: 32, height: 32)
                                    .background(softPink)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 10) {
                            Button(action: {
                                appState.saveApiKey(apiKeyInput)
                            }) {
                                Text("Сохранить")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            colors: [pinkColor, lightPink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .disabled(apiKeyInput.isEmpty)
                            .opacity(apiKeyInput.isEmpty ? 0.5 : 1)

                            if !appState.apiKey.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(pinkColor)
                                    Text("Сохранён")
                                        .font(.system(size: 11))
                                        .foregroundColor(textColor.opacity(0.6))
                                }
                            }
                        }

                        Divider()
                            .padding(.vertical, 2)

                        Link(destination: URL(string: "https://console.deepgram.com/signup")!) {
                            HStack(spacing: 6) {
                                Text("🎁")
                                Text("Получить бесплатно")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(pinkColor)
                        }

                        Text("$200 кредитов при регистрации")
                            .font(.system(size: 10))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }

                // Auto-paste section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "doc.on.clipboard.fill",
                            title: "Автовставка",
                            color: pinkColor
                        )

                        Toggle(isOn: Binding(
                            get: { appState.autoPasteEnabled },
                            set: { appState.saveAutoPaste($0) }
                        )) {
                            Text("Вставлять текст автоматически")
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                        }
                        .toggleStyle(.switch)
                        .tint(pinkColor)

                        Text("Текст появится там, где курсор")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))

                        Divider()
                            .padding(.vertical, 2)

                        Toggle(isOn: Binding(
                            get: { appState.textCleaningEnabled },
                            set: { appState.saveTextCleaningEnabled($0) }
                        )) {
                            Text("Очищать слова-паразиты")
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                        }
                        .toggleStyle(.switch)
                        .tint(pinkColor)

                        Text("Удаляет «ну», «как бы», «типа» и др.")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }

                // Floating window section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "rectangle.on.rectangle",
                            title: "Окно записи",
                            color: pinkColor
                        )

                        Toggle(isOn: Binding(
                            get: { appState.showFloatingWindow },
                            set: { appState.saveShowFloatingWindow($0) }
                        )) {
                            Text("Показывать плавающее окно")
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                        }
                        .toggleStyle(.switch)
                        .tint(pinkColor)

                        Text("Визуализация звука во время записи")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }

                // Pro mode section (Agent Feedback)
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Обратная связь для агента",
                            color: pinkColor
                        )

                        Toggle(isOn: Binding(
                            get: { appState.proModeEnabled },
                            set: { appState.saveProModeEnabled($0) }
                        )) {
                            Text("Включить режим агента")
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                        }
                        .toggleStyle(.switch)
                        .tint(pinkColor)

                        Text("Скриншот + голосовой комментарий для агента")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))

                        if appState.proModeEnabled {
                            Divider()
                                .padding(.vertical, 2)

                            // Fixed hotkeys info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Горячие клавиши:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(textColor)

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text("Right ⌘")
                                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                .foregroundColor(pinkColor)
                                            Text("→")
                                                .foregroundColor(textColor.opacity(0.4))
                                            Text("Голос")
                                                .font(.system(size: 11))
                                                .foregroundColor(textColor.opacity(0.7))
                                        }
                                        HStack(spacing: 6) {
                                            Text("⌥ Space")
                                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                .foregroundColor(pinkColor)
                                            Text("→")
                                                .foregroundColor(textColor.opacity(0.4))
                                            Text("Скриншот + голос")
                                                .font(.system(size: 11))
                                                .foregroundColor(textColor.opacity(0.7))
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                .background(softPink)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Divider()
                                .padding(.vertical, 2)

                            // Export folder
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Папка для экспорта")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(textColor)

                                HStack(spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(pinkColor)
                                        Text(exportFolderName)
                                            .font(.system(size: 11))
                                            .foregroundColor(textColor.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(softPink)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Spacer()

                                    Button(action: selectExportFolder) {
                                        Text("Выбрать")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(pinkColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Text("PNG и MD файлы для агента")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.4))
                            }
                        }
                    }
                }

                // Hotkey section (hidden when Pro mode is enabled)
                if !appState.proModeEnabled {
                    SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsCardHeader(
                                icon: "keyboard",
                                title: "Горячая клавиша",
                                color: pinkColor
                            )

                            // Hotkey mode picker
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(HotkeyMode.allCases, id: \.self) { mode in
                                    HotkeyModeRow(
                                        mode: mode,
                                        isSelected: appState.hotkeyMode == mode,
                                        pinkColor: pinkColor,
                                        softPink: softPink,
                                        textColor: textColor
                                    ) {
                                        appState.saveHotkeyMode(mode)
                                    }
                                }
                            }

                            // Show accessibility status for modes that need it
                            if appState.hotkeyMode.needsEventMonitoring {
                                Divider()
                                    .padding(.vertical, 2)

                                HStack {
                                    if appState.hasAccessibilityPermission {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(pinkColor)
                                            Text("Доступ разрешён")
                                                .font(.system(size: 11))
                                                .foregroundColor(textColor.opacity(0.6))
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("Нужен Универсальный доступ")
                                                .font(.system(size: 11))
                                                .foregroundColor(textColor.opacity(0.6))
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        appState.requestAccessibility()
                                    }) {
                                        Text("Настроить")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(pinkColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // About section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 10) {
                        SettingsCardHeader(
                            icon: "heart.fill",
                            title: "О приложении",
                            color: pinkColor
                        )

                        Text("Говорилка превращает голос в текст с помощью ИИ")
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.7))

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "https://deepgram.com")!) {
                                HStack(spacing: 4) {
                                    Text("🎙")
                                    Text("Deepgram")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(pinkColor)
                            }

                            Link(destination: URL(string: "https://github.com/skylineyoga/govorilka")!) {
                                HStack(spacing: 4) {
                                    Text("⭐")
                                    Text("GitHub")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(pinkColor)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(softPink.opacity(0.3))
        .onAppear {
            apiKeyInput = appState.apiKey
            appState.refreshAccessibilityStatus()
            updateExportFolderName()
        }
    }

    private func selectExportFolder() {
        let panel = NSOpenPanel()
        panel.title = "Выберите папку для экспорта"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.saveExportFolder(url)
            updateExportFolderName()
        }
    }

    private func updateExportFolderName() {
        if let url = StorageService.shared.resolveExportFolder() {
            exportFolderName = url.lastPathComponent
            StorageService.shared.stopAccessingExportFolder(url)
        } else {
            exportFolderName = "Не выбрана"
        }
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let pinkColor: Color
    let softPink: Color
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Settings Card Header

struct SettingsCardHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "5D4E6D"))
        }
        .padding(.bottom, 2)
    }
}

// MARK: - Hotkey Mode Row

struct HotkeyModeRow: View {
    let mode: HotkeyMode
    let isSelected: Bool
    let pinkColor: Color
    let softPink: Color
    let textColor: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? pinkColor : textColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)

                    if isSelected {
                        Circle()
                            .fill(pinkColor)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(mode.displayName)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? pinkColor : textColor)

                        if mode == .rightCommand {
                            Text("рекомендуется")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(pinkColor.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(mode.description)
                        .font(.system(size: 10))
                        .foregroundColor(textColor.opacity(0.5))
                }

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? softPink : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(appState: AppState())
        .frame(width: 340, height: 500)
}
