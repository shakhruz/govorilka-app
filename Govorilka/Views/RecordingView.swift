import KeyboardShortcuts
import SwiftUI

/// Recording indicator and current transcript display
struct RecordingView: View {
    @ObservedObject var appState: AppState

    @State private var animationPhase = 0.0

    var body: some View {
        VStack(spacing: 12) {
            // Status indicator
            HStack(spacing: 8) {
                // Recording indicator
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 12, height: 12)
                    .overlay {
                        if appState.isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                .scaleEffect(1 + animationPhase * 0.5)
                                .opacity(1 - animationPhase)
                        }
                    }
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: animationPhase)

                Text(statusText)
                    .font(.headline)
                    .foregroundColor(appState.isRecording ? .primary : .secondary)

                Spacer()

                if appState.isRecording {
                    Text(formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            .onAppear {
                animationPhase = 1.0
            }

            // Record button
            Button(action: {
                appState.toggleRecording()
            }) {
                HStack {
                    if appState.isConnecting {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    } else {
                        Image(systemName: appState.isRecording ? "stop.fill" : "mic.fill")
                    }

                    Text(buttonText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(appState.isRecording ? .red : .accentColor)
            .disabled(appState.isConnecting)

            // Hotkey hint
            HStack {
                Text("Хоткей:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                KeyboardShortcuts.Recorder(for: .toggleRecording)
                    .controlSize(.small)
            }

            // Current transcript
            if appState.isRecording || !appState.currentTranscript.isEmpty || !appState.interimTranscript.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Транскрипция:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(displayTranscript)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 80)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var indicatorColor: Color {
        if appState.isRecording {
            return .red
        } else if appState.isConnecting {
            return .orange
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if appState.isRecording {
            return "Запись..."
        } else if appState.isConnecting {
            return "Подключение..."
        } else {
            return "Готово к записи"
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
        .frame(width: 300)
}
