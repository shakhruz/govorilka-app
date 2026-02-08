import SwiftUI

/// Reusable permission card component used in onboarding and settings
struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionStatus
    let actionLabel: String
    let action: () -> Void
    let isOptional: Bool

    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let textColor = Theme.text
    private let softPink = Theme.softPink

    init(
        icon: String,
        title: String,
        description: String,
        status: PermissionStatus,
        actionLabel: String = "Разрешить",
        isOptional: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.status = status
        self.actionLabel = actionLabel
        self.isOptional = isOptional
        self.action = action
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(status == .granted ? .green : pinkColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(status == .granted ? Color.green.opacity(0.1) : softPink)
                )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(textColor)

                    if isOptional {
                        Text("опционально")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(textColor.opacity(0.5))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(softPink)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(textColor.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()

            // Status / Action
            if status == .granted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            } else {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
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
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Keyboard Key View

struct KeyboardKeyView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(Theme.text)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.grayBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 12) {
        PermissionCard(
            icon: "mic.fill",
            title: "Микрофон",
            description: "Для записи голоса",
            status: .granted,
            action: {}
        )
        PermissionCard(
            icon: "accessibility",
            title: "Универсальный доступ",
            description: "Для автовставки текста",
            status: .denied,
            actionLabel: "Открыть настройки",
            action: {}
        )
        PermissionCard(
            icon: "rectangle.dashed.badge.record",
            title: "Запись экрана",
            description: "Для скриншотов (Pro режим)",
            status: .notDetermined,
            actionLabel: "Настроить",
            isOptional: true,
            action: {}
        )
    }
    .padding()
    .background(Theme.softPink.opacity(0.3))
}
