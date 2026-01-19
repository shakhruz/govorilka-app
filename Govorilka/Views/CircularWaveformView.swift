import SwiftUI

/// Circular waveform indicator with pulsing rings that react to audio level
struct CircularWaveformView: View {
    /// Audio level from 0.0 to 1.0
    @Binding var audioLevel: Float

    /// Whether recording is active
    var isRecording: Bool

    /// Size of the view
    var size: CGFloat = 120

    /// Gradient colors for the rings
    private let gradientColors = [
        Color(red: 0.31, green: 0.27, blue: 0.90), // #4F46E5 - Blue
        Color(red: 0.49, green: 0.23, blue: 0.93)  // #7C3AED - Purple
    ]

    @State private var pulseAnimation = false
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring3Scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer ring 3 (largest, slowest pulse)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: gradientColors.map { $0.opacity(0.15) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: size, height: size)
                .scaleEffect(ring3Scale)
                .opacity(isRecording ? 0.6 : 0.2)

            // Ring 2 (middle)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: gradientColors.map { $0.opacity(0.25) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: size * 0.75, height: size * 0.75)
                .scaleEffect(ring2Scale)
                .opacity(isRecording ? 0.7 : 0.3)

            // Ring 1 (inner ring)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: gradientColors.map { $0.opacity(0.4) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: size * 0.55, height: size * 0.55)
                .scaleEffect(ring1Scale)
                .opacity(isRecording ? 0.85 : 0.4)

            // Center circle with microphone
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.4, height: size * 0.4)
                    .shadow(
                        color: gradientColors[1].opacity(isRecording ? 0.6 : 0.3),
                        radius: isRecording ? 15 + CGFloat(audioLevel) * 10 : 5,
                        x: 0,
                        y: 0
                    )

                // Microphone icon
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: size * 0.15, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: audioLevel) { newLevel in
            updateRingsForAudioLevel(newLevel)
        }
        .onChange(of: isRecording) { recording in
            if recording {
                startPulseAnimation()
            } else {
                stopPulseAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startPulseAnimation()
            }
        }
    }

    // MARK: - Animation Methods

    private func updateRingsForAudioLevel(_ level: Float) {
        let normalizedLevel = CGFloat(min(max(level, 0), 1))

        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            ring1Scale = 1.0 + normalizedLevel * 0.3
            ring2Scale = 1.0 + normalizedLevel * 0.2
            ring3Scale = 1.0 + normalizedLevel * 0.15
        }
    }

    private func startPulseAnimation() {
        pulseAnimation = true

        // Animate rings with different speeds
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            ring3Scale = 1.1
        }

        withAnimation(
            .easeInOut(duration: 0.9)
            .repeatForever(autoreverses: true)
            .delay(0.1)
        ) {
            ring2Scale = 1.15
        }

        withAnimation(
            .easeInOut(duration: 0.7)
            .repeatForever(autoreverses: true)
            .delay(0.2)
        ) {
            ring1Scale = 1.2
        }
    }

    private func stopPulseAnimation() {
        pulseAnimation = false

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            ring1Scale = 1.0
            ring2Scale = 1.0
            ring3Scale = 1.0
        }
    }
}

// MARK: - Preview

#Preview("Recording") {
    CircularWaveformView(
        audioLevel: .constant(0.5),
        isRecording: true
    )
    .padding(40)
    .background(Color.black.opacity(0.8))
}

#Preview("Idle") {
    CircularWaveformView(
        audioLevel: .constant(0.0),
        isRecording: false
    )
    .padding(40)
    .background(Color.black.opacity(0.8))
}
