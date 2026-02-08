import AppKit
import SwiftUI

/// Beautiful simplified settings view with pink theme
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var purchaseService = PurchaseService.shared

    @State private var apiKeyInput = ""
    @State private var showApiKey = false
    @State private var exportFolderName: String = "Не выбрана"
    @State private var llmApiKeyInput = ""
    @State private var showLLMApiKey = false
    @State private var llmApiKeySaved = false

    // Theme colors (use centralized Theme constants)
    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let softPink = Theme.softPink
    private let textColor = Theme.text

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
                                    .foregroundColor(textColor)
                                    .padding(10)
                                    .background(softPink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                SecureField("Введите API ключ", text: $apiKeyInput)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(textColor)
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

                // AI Touch section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "wand.and.stars",
                            title: "AI Touch",
                            color: pinkColor
                        )

                        Text("Улучшение транскрипции с помощью ИИ")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))

                        HStack(spacing: 8) {
                            if showLLMApiKey {
                                TextField("Введите Groq API ключ", text: $llmApiKeyInput)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(textColor)
                                    .padding(10)
                                    .background(softPink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                SecureField("Введите Groq API ключ", text: $llmApiKeyInput)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(textColor)
                                    .padding(10)
                                    .background(softPink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button(action: { showLLMApiKey.toggle() }) {
                                Image(systemName: showLLMApiKey ? "eye.slash.fill" : "eye.fill")
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
                                appState.saveLLMApiKey(llmApiKeyInput)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    llmApiKeySaved = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        llmApiKeySaved = false
                                    }
                                }
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
                            .disabled(llmApiKeyInput.isEmpty)
                            .opacity(llmApiKeyInput.isEmpty ? 0.5 : 1)

                            if llmApiKeySaved || StorageService.shared.hasLLMApiKey {
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

                        Link(destination: URL(string: "https://console.groq.com/keys")!) {
                            HStack(spacing: 6) {
                                Text("🔑")
                                Text("Получить API ключ")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(pinkColor)
                        }

                        Text("Бесплатно: 30 запросов/мин")
                            .font(.system(size: 10))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }

                // Supporter section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: purchaseService.isSupporter ? "heart.fill" : "heart")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(pinkColor)
                            Text(purchaseService.isSupporter ? "Спасибо за поддержку!" : "Поддержать разработку")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(textColor)

                            Spacer()

                            if purchaseService.isSupporter {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(pinkColor)
                                    Text("Supporter")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(pinkColor)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(softPink)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.bottom, 2)

                        if !purchaseService.isSupporter {
                            Text("Говорилка — open-source и бесплатна. Покупка поддерживает разработку и даёт автообновления из App Store.")
                                .font(.system(size: 12))
                                .foregroundColor(textColor.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)

                            HStack(spacing: 10) {
                                Button(action: {
                                    Task {
                                        await purchaseService.purchaseSupporter()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        if purchaseService.isPurchasing {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .frame(width: 14, height: 14)
                                        } else {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 11))
                                        }
                                        Text(purchaseService.formattedPrice)
                                            .font(.system(size: 12, weight: .semibold))
                                    }
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
                                    .shadow(color: pinkColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                                .disabled(purchaseService.isPurchasing || purchaseService.supporterProduct == nil)

                                Button(action: {
                                    Task {
                                        await purchaseService.restorePurchases()
                                    }
                                }) {
                                    Text("Восстановить")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(pinkColor)
                                }
                                .buttonStyle(.plain)
                                .disabled(purchaseService.isPurchasing)
                            }

                            if let error = purchaseService.errorMessage {
                                Text(error)
                                    .font(.system(size: 10))
                                    .foregroundColor(.red.opacity(0.8))
                            }

                            Divider()
                                .padding(.vertical, 2)

                            Link(destination: URL(string: "https://github.com/skylineyoga/govorilka")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 10))
                                    Text("Собрать бесплатно из исходников")
                                        .font(.system(size: 11, weight: .medium))
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(textColor.opacity(0.6))
                            }
                        } else {
                            Text("Вы помогаете развивать Говорилку. Спасибо!")
                                .font(.system(size: 12))
                                .foregroundColor(textColor.opacity(0.7))
                        }
                    }
                }

                // Permissions section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "lock.shield.fill",
                            title: "Разрешения",
                            color: pinkColor
                        )

                        PermissionCard(
                            icon: "mic.fill",
                            title: "Микрофон",
                            description: "Запись голоса для транскрипции",
                            status: appState.permissionManager.microphoneStatus,
                            actionLabel: "Разрешить"
                        ) {
                            Task {
                                _ = await appState.permissionManager.requestMicrophoneAccess()
                            }
                        }

                        PermissionCard(
                            icon: "accessibility",
                            title: "Универсальный доступ",
                            description: "Автовставка текста и горячие клавиши",
                            status: appState.permissionManager.accessibilityStatus,
                            actionLabel: "Открыть настройки"
                        ) {
                            appState.requestAccessibility()
                        }

                        PermissionCard(
                            icon: "rectangle.dashed.badge.record",
                            title: "Запись экрана",
                            description: "Скриншоты для режима агента",
                            status: appState.permissionManager.screenRecordingStatus,
                            actionLabel: "Настроить",
                            isOptional: true
                        ) {
                            appState.openScreenRecordingSettings()
                        }

                        Divider()
                            .padding(.vertical, 2)

                        HStack(spacing: 10) {
                            Button(action: {
                                appState.refreshPermissions()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11))
                                    Text("Обновить")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(pinkColor)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: {
                                showTCCResetInstructions()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 11))
                                    Text("Сброс разрешений")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(textColor.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
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

                        // Accessibility status for auto-paste (compact)
                        if appState.autoPasteEnabled && appState.permissionManager.accessibilityStatus != .granted {
                            Divider()
                                .padding(.vertical, 2)

                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 10))
                                Text("Нужен Универсальный доступ — см. секцию «Разрешения»")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.5))
                            }
                        }
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

                // Sound feedback section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "speaker.wave.2.fill",
                            title: "Звуки",
                            color: pinkColor
                        )

                        Toggle(isOn: Binding(
                            get: { appState.soundsEnabled },
                            set: { appState.saveSoundsEnabled($0) }
                        )) {
                            Text("Звуковые уведомления")
                                .font(.system(size: 13))
                                .foregroundColor(textColor)
                        }
                        .toggleStyle(.switch)
                        .tint(pinkColor)

                        Text("Звуки при начале/окончании записи")
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

                        // Screen Recording status (compact)
                        if appState.permissionManager.screenRecordingStatus != .granted {
                            Divider()
                                .padding(.vertical, 2)

                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 10))
                                Text("Нужен доступ к экрану — см. секцию «Разрешения»")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.5))
                            }
                        }

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
                        }
                    }
                }

                // Export folder section (always visible, not Pro-only)
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "folder.fill",
                            title: "Папка для экспорта",
                            color: pinkColor
                        )

                        Text("Автоматически сохранять записи в выбранную папку")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))

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

                        Text("PNG и TXT файлы сохраняются автоматически")
                            .font(.system(size: 10))
                            .foregroundColor(textColor.opacity(0.4))
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

                            // Show accessibility status for modes that need it (compact)
                            if appState.hotkeyMode.needsEventMonitoring && appState.permissionManager.accessibilityStatus != .granted {
                                Divider()
                                    .padding(.vertical, 2)

                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 10))
                                    Text("Нужен Универсальный доступ — см. «Разрешения»")
                                        .font(.system(size: 10))
                                        .foregroundColor(textColor.opacity(0.5))
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
            llmApiKeyInput = StorageService.shared.llmApiKey ?? ""
            appState.refreshPermissions()
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

    private func showTCCResetInstructions() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Сброс разрешений"
        alert.informativeText = """
        Если разрешения работают некорректно, выполните в Терминале:

        tccutil reset Microphone com.govorilka.app
        tccutil reset Accessibility com.govorilka.app
        tccutil reset ScreenCapture com.govorilka.app

        После этого перезапустите Говорилку — система запросит разрешения заново.
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
