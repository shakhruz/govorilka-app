import SwiftUI

/// Welcome onboarding view with usage instructions
struct AccessibilityOnboardingView: View {
    @Binding var dontShowAgain: Bool
    var onOpenSettings: () -> Void
    var onSkip: () -> Void

    @State private var hasAppeared = false
    @State private var isButtonHovered = false
    @State private var isCloseHovered = false

    // Theme colors (use centralized Theme constants)
    private let backgroundColor = Theme.backgroundGradient
    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let textColor = Theme.text

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onSkip) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(isCloseHovered ? Color.secondary : Color.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isCloseHovered = hovering
                        }
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                }
                Spacer()
            }
            .zIndex(1)

            VStack(spacing: 14) {
                Spacer().frame(height: 40)

                // Cloud mascot
                SmilingCloudView()
                    .scaleEffect(0.9)

                // Greeting
                Text("Привет! Я Говорилка")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(textColor)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)

                // Subtitle
                Text("Превращаю твой голос в текст ✨")
                    .font(.system(size: 15))
                    .foregroundColor(textColor.opacity(0.7))
                    .opacity(hasAppeared ? 1 : 0)

                Spacer().frame(height: 6)

                // Instructions card
                instructionsCard
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)

                Spacer().frame(height: 12)

                // Start button
                Button(action: onSkip) {
                    HStack(spacing: 8) {
                        Text("Понятно!")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [pinkColor, lightPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(
                        color: pinkColor.opacity(isButtonHovered ? 0.5 : 0.3),
                        radius: isButtonHovered ? 14 : 10,
                        x: 0,
                        y: isButtonHovered ? 6 : 4
                    )
                    .scaleEffect(isButtonHovered ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isButtonHovered = hovering
                    }
                }
                .opacity(hasAppeared ? 1 : 0)

                // Don't show again
                Toggle("Больше не показывать", isOn: $dontShowAgain)
                    .toggleStyle(.checkbox)
                    .foregroundColor(textColor.opacity(0.5))
                    .font(.system(size: 12))
                    .opacity(hasAppeared ? 1 : 0)

                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 20)
        }
        .frame(width: 380, height: 540)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                hasAppeared = true
            }
        }
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Как пользоваться:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(textColor)

            instructionRow(
                icon: "1️⃣",
                title: "Правый ⌘",
                subtitle: "Начнётся запись голоса"
            )

            instructionRow(
                icon: "2️⃣",
                title: "Говори что хочешь",
                subtitle: "Я слушаю и записываю"
            )

            instructionRow(
                icon: "3️⃣",
                title: "Снова ⌘",
                subtitle: "Текст появится там, где курсор"
            )

            // Keyboard hint
            HStack(spacing: 8) {
                KeyboardKeyView(text: "⌘")
                Text("→")
                    .foregroundColor(textColor.opacity(0.5))
                Image(systemName: "mic.fill")
                    .foregroundColor(pinkColor)
                Text("→")
                    .foregroundColor(textColor.opacity(0.5))
                KeyboardKeyView(text: "⌘")
                Text("→")
                    .foregroundColor(textColor.opacity(0.5))
                Image(systemName: "doc.on.clipboard.fill")
                    .foregroundColor(pinkColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(pinkColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func instructionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 18))

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
}

// MARK: - Keyboard Key View

struct KeyboardKeyView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(Color(hex: "5D4E6D"))
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "F0F0F0"))
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
    }
}

#Preview {
    AccessibilityOnboardingView(
        dontShowAgain: .constant(false),
        onOpenSettings: {},
        onSkip: {}
    )
}
