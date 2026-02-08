import SwiftUI
import Combine

/// Multi-step permissions onboarding view
struct OnboardingPermissionsView: View {
    @ObservedObject var permissionManager: PermissionManager
    var onComplete: () -> Void

    @State private var currentStep = 0
    @State private var hasAppeared = false
    @State private var isButtonHovered = false
    @State private var timer: AnyCancellable?

    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let textColor = Theme.text
    private let softPink = Theme.softPink
    private let backgroundColor = Theme.backgroundGradient

    /// Total number of steps: welcome, mic, accessibility, screen recording, hotkey
    private let totalSteps = 5

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // Content area
                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: microphoneStep
                    case 2: accessibilityStep
                    case 3: screenRecordingStep
                    case 4: hotkeyStep
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(width: 380, height: 640)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                hasAppeared = true
            }
            startPermissionPolling()
        }
        .onDisappear {
            timer?.cancel()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? pinkColor : pinkColor.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 30)

            SmilingCloudView()
                .scaleEffect(0.85)
                .opacity(hasAppeared ? 1 : 0)

            Text("Привет! Я Говорилка")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)

            Text("Превращаю твой голос в текст")
                .font(.system(size: 15))
                .foregroundColor(textColor.opacity(0.7))
                .opacity(hasAppeared ? 1 : 0)

            Spacer().frame(height: 8)

            Text("Для работы мне нужны несколько разрешений.\nЭто займёт минуту!")
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1 : 0)

            Spacer()

            nextButton(title: "Начать настройку") {
                withAnimation { currentStep = 1 }
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step 1: Microphone

    private var microphoneStep: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            stepIcon("mic.fill")

            Text("Микрофон")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textColor)

            Text("Нужен для записи голоса и преобразования в текст")
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            PermissionCard(
                icon: "mic.fill",
                title: "Микрофон",
                description: "Запись голоса для транскрипции",
                status: permissionManager.microphoneStatus,
                actionLabel: "Разрешить"
            ) {
                Task {
                    _ = await permissionManager.requestMicrophoneAccess()
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            if permissionManager.microphoneStatus == .granted {
                nextButton(title: "Далее") {
                    withAnimation { currentStep = 2 }
                }
            } else if permissionManager.microphoneStatus == .denied {
                VStack(spacing: 8) {
                    Text("Если кнопка не помогает, откройте настройки вручную")
                        .font(.system(size: 11))
                        .foregroundColor(textColor.opacity(0.5))
                        .multilineTextAlignment(.center)

                    Button("Открыть Настройки системы") {
                        permissionManager.openMicrophoneSettings()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(pinkColor)
                    .buttonStyle(.plain)
                }
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step 2: Accessibility

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            stepIcon("accessibility")

            Text("Универсальный доступ")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textColor)

            Text("Нужен для автовставки текста и горячих клавиш")
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            PermissionCard(
                icon: "accessibility",
                title: "Универсальный доступ",
                description: "Автовставка текста в любое приложение",
                status: permissionManager.accessibilityStatus,
                actionLabel: "Открыть настройки"
            ) {
                permissionManager.openAccessibilitySettings()
            }
            .padding(.horizontal, 16)

            if permissionManager.accessibilityStatus != .granted {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Ожидаю разрешения...")
                        .font(.system(size: 11))
                        .foregroundColor(textColor.opacity(0.5))
                }
                .padding(.top, 4)
            }

            Spacer()

            if permissionManager.accessibilityStatus == .granted {
                nextButton(title: "Далее") {
                    withAnimation { currentStep = 3 }
                }
            } else {
                skipButton {
                    withAnimation { currentStep = 3 }
                }
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step 3: Screen Recording (Optional)

    private var screenRecordingStep: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            stepIcon("rectangle.dashed.badge.record")

            Text("Запись экрана")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textColor)

            HStack(spacing: 4) {
                Text("опционально")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(textColor.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(softPink)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text("Для скриншотов в Pro режиме (обратная связь агенту)")
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer().frame(height: 12)

            PermissionCard(
                icon: "rectangle.dashed.badge.record",
                title: "Запись экрана",
                description: "Скриншоты для режима агента",
                status: permissionManager.screenRecordingStatus,
                actionLabel: "Настроить",
                isOptional: true
            ) {
                permissionManager.openScreenRecordingSettings()
            }
            .padding(.horizontal, 16)

            Spacer()

            if permissionManager.screenRecordingStatus == .granted {
                nextButton(title: "Далее") {
                    withAnimation { currentStep = 4 }
                }
            } else {
                VStack(spacing: 12) {
                    skipButton {
                        withAnimation { currentStep = 4 }
                    }

                    Text("Можно настроить позже в Настройках")
                        .font(.system(size: 11))
                        .foregroundColor(textColor.opacity(0.4))
                }
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Step 4: Hotkey Info

    private var hotkeyStep: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 30)

            SmilingCloudView()
                .scaleEffect(0.75)

            Text("Готово!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)

            // Permission summary
            VStack(spacing: 8) {
                permissionSummaryRow("mic.fill", "Микрофон", permissionManager.microphoneStatus)
                permissionSummaryRow("accessibility", "Универсальный доступ", permissionManager.accessibilityStatus)
                permissionSummaryRow("rectangle.dashed.badge.record", "Запись экрана", permissionManager.screenRecordingStatus)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            // Hotkey instructions
            VStack(alignment: .leading, spacing: 12) {
                Text("Как пользоваться:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)

                hotkeyRow("1️⃣", "Правый ⌘", "Начнётся запись голоса")
                hotkeyRow("2️⃣", "Говори что хочешь", "Я слушаю и записываю")
                hotkeyRow("3️⃣", "Снова ⌘", "Текст появится там, где курсор")

                HStack(spacing: 8) {
                    KeyboardKeyView(text: "⌘")
                    Text("→").foregroundColor(textColor.opacity(0.5))
                    Image(systemName: "mic.fill").foregroundColor(pinkColor)
                    Text("→").foregroundColor(textColor.opacity(0.5))
                    KeyboardKeyView(text: "⌘")
                    Text("→").foregroundColor(textColor.opacity(0.5))
                    Image(systemName: "doc.on.clipboard.fill").foregroundColor(pinkColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(pinkColor.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 16)

            Spacer()

            nextButton(title: "Понятно!") {
                onComplete()
            }

            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Helpers

    private func stepIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 44))
            .foregroundColor(pinkColor)
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(softPink)
            )
    }

    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                if currentStep < totalSteps - 1 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 36)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [pinkColor, lightPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: pinkColor.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func skipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Пропустить")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textColor.opacity(0.5))
        }
        .buttonStyle(.plain)
    }

    private func permissionSummaryRow(_ icon: String, _ title: String, _ status: PermissionStatus) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(status == .granted ? .green : .orange)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(textColor)

            Spacer()

            Image(systemName: status == .granted ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 16))
                .foregroundColor(status == .granted ? .green : .orange)
        }
    }

    private func hotkeyRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                permissionManager.checkAllPermissions()

                // Auto-advance if permission granted on current step
                switch currentStep {
                case 1:
                    if permissionManager.microphoneStatus == .granted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation { currentStep = 2 }
                        }
                    }
                case 2:
                    if permissionManager.accessibilityStatus == .granted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation { currentStep = 3 }
                        }
                    }
                case 3:
                    if permissionManager.screenRecordingStatus == .granted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation { currentStep = 4 }
                        }
                    }
                default:
                    break
                }
            }
    }
}

#Preview {
    OnboardingPermissionsView(
        permissionManager: PermissionManager.shared,
        onComplete: {}
    )
}
