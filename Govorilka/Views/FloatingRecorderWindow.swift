import SwiftUI

/// Floating recorder window view with pink cloud style
struct FloatingRecorderView: View {
    @ObservedObject var appState: AppState
    @Binding var audioLevel: Float
    var onClose: () -> Void

    @State private var recordingTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isStopButtonHovered = false
    @State private var isCancelHovered = false
    @State private var isCameraHovered = false

    // Pink color scheme
    private let pinkColor = Color(hex: "FF69B4")
    private let lightPink = Color(hex: "FFB6C1")
    private let textColor = Color(hex: "5D4E6D")

    private let backgroundColor = LinearGradient(
        colors: [Color(hex: "FFF5F8"), Color(hex: "FFE4EC")],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        VStack(spacing: 12) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    appState.cancelRecording()
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(textColor.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Закрыть")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Cloud mascot with audio reactivity
            CompactCloudView(
                audioLevel: $audioLevel,
                isRecording: appState.isRecording
            )
            .padding(.top, 4)

            // Recording time and camera button
            HStack(spacing: 12) {
                Text(formatDuration(recordingTime))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(pinkColor)

                // Camera button
                Button(action: {
                    appState.captureScreenshotDuringRecording()
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isCameraHovered ? .white : pinkColor)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isCameraHovered ? pinkColor : pinkColor.opacity(0.15))
                        )
                        .scaleEffect(isCameraHovered ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isCameraHovered = hovering
                    }
                }
                .help("Сделать скриншот")
            }

            // Screenshot thumbnails (if any)
            if !appState.capturedScreenshots.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(appState.capturedScreenshots.enumerated()), id: \.offset) { index, screenshot in
                            Image(nsImage: screenshot)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 36, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(pinkColor.opacity(0.5), lineWidth: 1)
                                )
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(2)
                                        .background(pinkColor.opacity(0.8))
                                        .clipShape(Circle())
                                        .offset(x: 12, y: -8),
                                    alignment: .topTrailing
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 28)
            }

            // Live transcript preview
            Text(transcriptPreview)
                .font(.system(size: 12))
                .foregroundColor(textColor.opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .padding(.horizontal, 16)

            Spacer()

            // Stop button
            Button(action: {
                appState.stopRecording()
                onClose()
            }) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                    Text("Остановить")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [pinkColor, lightPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(
                    color: pinkColor.opacity(isStopButtonHovered ? 0.5 : 0.3),
                    radius: isStopButtonHovered ? 12 : 8,
                    x: 0,
                    y: isStopButtonHovered ? 6 : 4
                )
                .scaleEffect(isStopButtonHovered ? 1.03 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isStopButtonHovered = hovering
                }
            }

            // Cancel link
            Button(action: {
                appState.cancelRecording()
                onClose()
            }) {
                Text("Отменить")
                    .font(.system(size: 13))
                    .foregroundColor(isCancelHovered ? textColor : textColor.opacity(0.5))
                    .underline(isCancelHovered)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isCancelHovered = hovering
                }
            }
            .padding(.bottom, 16)
        }
        .frame(width: 200, height: appState.capturedScreenshots.isEmpty ? 300 : 340)
        .background(PinkBackground())
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: pinkColor.opacity(0.2), radius: 20, x: 0, y: 10)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: appState.isRecording) { isRecording in
            if isRecording {
                recordingTime = 0
                startTimer()
            } else {
                stopTimer()
            }
        }
    }

    // MARK: - Computed Properties

    private var transcriptPreview: String {
        let text = appState.interimTranscript.isEmpty
            ? appState.currentTranscript
            : appState.interimTranscript

        if text.isEmpty {
            return "Слушаю..."
        }

        // Show last 50 characters
        if text.count > 50 {
            return "..." + String(text.suffix(50))
        }
        return text
    }

    // MARK: - Timer Methods

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if appState.isRecording {
                recordingTime = appState.recordingDuration
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Pink Background

struct PinkBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [Color(hex: "FFF5F8"), Color(hex: "FFE4EC")],
                startPoint: .top,
                endPoint: .bottom
            )

            // Subtle overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.5),
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Border effect
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color(hex: "FFB6C1").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Preview

#Preview("Recording") {
    FloatingRecorderView(
        appState: AppState(),
        audioLevel: .constant(0.3),
        onClose: {}
    )
    .padding(40)
}
