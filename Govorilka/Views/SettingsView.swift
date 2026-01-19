import SwiftUI

/// Beautiful simplified settings view with pink theme
struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var apiKeyInput = ""
    @State private var showApiKey = false

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

                        if appState.autoPasteEnabled {
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
                                        Text("Нужен доступ")
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

                // Hotkey section
                SettingsCard(pinkColor: pinkColor, softPink: softPink) {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsCardHeader(
                            icon: "keyboard",
                            title: "Горячая клавиша",
                            color: pinkColor
                        )

                        HotkeySelector(
                            selectedMode: appState.hotkeyMode,
                            pinkColor: pinkColor,
                            textColor: textColor,
                            softPink: softPink
                        ) { mode in
                            appState.saveHotkeyMode(mode)
                        }

                        Text(appState.hotkeyMode.description)
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)

                        // Show warning for double-tap modes if no accessibility permission
                        if appState.hotkeyMode != .optionSpace && appState.hotkeyMode != .custom {
                            if !appState.hasAccessibilityPermission {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 11))
                                    Text("Требуется доступ к Универсальному доступу")
                                        .font(.system(size: 10))
                                        .foregroundColor(textColor.opacity(0.7))

                                    Spacer()

                                    Button(action: {
                                        appState.requestAccessibility()
                                    }) {
                                        Text("Настроить")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(pinkColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.top, 4)
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

// MARK: - Hotkey Selector

struct HotkeySelector: View {
    let selectedMode: HotkeyMode
    let pinkColor: Color
    let textColor: Color
    let softPink: Color
    let onSelect: (HotkeyMode) -> Void

    private let modes: [HotkeyMode] = [.optionSpace, .doubleTapFn, .doubleTapRightOption]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(modes, id: \.self) { mode in
                HotkeySelectorButton(
                    mode: mode,
                    isSelected: selectedMode == mode,
                    pinkColor: pinkColor,
                    textColor: textColor,
                    softPink: softPink
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        onSelect(mode)
                    }
                }
            }
        }
        .padding(4)
        .background(softPink.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HotkeySelectorButton: View {
    let mode: HotkeyMode
    let isSelected: Bool
    let pinkColor: Color
    let textColor: Color
    let softPink: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode.displayName)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : textColor.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [pinkColor, pinkColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: isSelected ? pinkColor.opacity(0.3) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(appState: AppState())
        .frame(width: 340, height: 500)
}
