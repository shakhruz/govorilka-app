import SwiftUI

/// Beautiful recording section with pink theme
struct RecordingView: View {
    @ObservedObject var appState: AppState

    @State private var animationPhase = 0.0
    @State private var isButtonHovered = false

    // Theme colors (use centralized Theme constants)
    private let pinkColor = Theme.pink
    private let lightPink = Theme.lightPink
    private let textColor = Theme.text
    private let recordingRed = Theme.recordingRed

    var body: some View {
        VStack(spacing: 14) {
            // Status with cute indicator
            HStack(spacing: 10) {
                // Recording indicator
                ZStack {
                    Circle()
                        .fill(indicatorColor.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Circle()
                        .fill(indicatorColor)
                        .frame(width: 12, height: 12)

                    if appState.isRecording {
                        Circle()
                            .stroke(recordingRed.opacity(0.5), lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .scaleEffect(1 + animationPhase * 0.5)
                            .opacity(1 - animationPhase)
                    }
                }
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: animationPhase)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)

                    if appState.isRecording {
                        Text(formattedDuration)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(textColor.opacity(0.6))
                    } else {
                        Text("⌥ + Пробел")
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }

                Spacer()
            }
            .onAppear {
                animationPhase = 1.0
            }

            // Big beautiful record button
            Button(action: {
                appState.toggleRecording()
            }) {
                HStack(spacing: 10) {
                    if appState.isConnecting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text(buttonText)
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: appState.isRecording
                                    ? [recordingRed, recordingRed.opacity(0.8)]
                                    : [pinkColor, lightPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: (appState.isRecording ? recordingRed : pinkColor).opacity(isButtonHovered ? 0.5 : 0.3),
                            radius: isButtonHovered ? 12 : 8,
                            x: 0,
                            y: isButtonHovered ? 5 : 3
                        )
                )
                .scaleEffect(isButtonHovered ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(appState.isConnecting)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isButtonHovered = hovering
                }
            }

            // Current transcript (collapsible)
            if appState.isRecording || !appState.currentTranscript.isEmpty || !appState.interimTranscript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "text.quote")
                            .font(.system(size: 11))
                            .foregroundColor(pinkColor)
                        Text("Транскрипция")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor.opacity(0.7))
                    }

                    ScrollView {
                        Text(displayTranscript)
                            .font(.system(size: 13))
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 60)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "FFF5F8"))
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Computed Properties

    private var indicatorColor: Color {
        if appState.isRecording {
            return recordingRed
        } else if appState.isConnecting {
            return .orange
        } else {
            return pinkColor
        }
    }

    private var statusText: String {
        if appState.isRecording {
            return "Слушаю..."
        } else if appState.isConnecting {
            return "Подключаюсь..."
        } else {
            return "Готова к записи"
        }
    }

    private var buttonText: String {
        if appState.isRecording {
            return "Остановить"
        } else if appState.isConnecting {
            return "Подключение..."
        } else {
            return "Начать запись"
        }
    }

    private var displayTranscript: String {
        var text = appState.currentTranscript
        if !appState.interimTranscript.isEmpty {
            if !text.isEmpty {
                text += " "
            }
            text += appState.interimTranscript
        }
        return text.isEmpty ? "..." : text
    }

    private var formattedDuration: String {
        let duration = appState.recordingDuration
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview("Idle") {
    RecordingView(appState: AppState())
        .padding()
        .frame(width: 320)
        .background(Color(hex: "FFF0F5"))
}
