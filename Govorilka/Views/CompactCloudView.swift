import SwiftUI

/// Pulsating audio wave rings around the cloud
struct AudioWaveRings: View {
    @Binding var audioLevel: Float
    var isRecording: Bool

    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring3Scale: CGFloat = 1.0
    @State private var ring1Opacity: Double = 0.6
    @State private var ring2Opacity: Double = 0.4
    @State private var ring3Opacity: Double = 0.2

    private let ringColor = Color(hex: "FFB6C1")

    var body: some View {
        ZStack {
            if isRecording {
                // Ring 1 - innermost, reacts most to audio
                Circle()
                    .stroke(ringColor, lineWidth: 2)
                    .frame(width: 100, height: 80)
                    .scaleEffect(ring1Scale + CGFloat(audioLevel) * 0.15)
                    .opacity(ring1Opacity)

                // Ring 2 - middle
                Circle()
                    .stroke(ringColor, lineWidth: 1.5)
                    .frame(width: 120, height: 96)
                    .scaleEffect(ring2Scale + CGFloat(audioLevel) * 0.1)
                    .opacity(ring2Opacity)

                // Ring 3 - outermost
                Circle()
                    .stroke(ringColor, lineWidth: 1)
                    .frame(width: 140, height: 112)
                    .scaleEffect(ring3Scale + CGFloat(audioLevel) * 0.05)
                    .opacity(ring3Opacity)
            }
        }
        .onAppear {
            startRingAnimations()
        }
        .onChange(of: isRecording) { recording in
            if recording {
                startRingAnimations()
            }
        }
    }

    private func startRingAnimations() {
        // Ring 1 - fast pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            ring1Scale = 1.08
            ring1Opacity = 0.8
        }

        // Ring 2 - medium pulse with delay
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.2)) {
            ring2Scale = 1.06
            ring2Opacity = 0.5
        }

        // Ring 3 - slow pulse with more delay
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.4)) {
            ring3Scale = 1.04
            ring3Opacity = 0.3
        }
    }
}

/// Compact cloud view for the floating recorder that reacts to audio level
struct CompactCloudView: View {
    /// Audio level from 0.0 to 1.0
    @Binding var audioLevel: Float

    /// Whether recording is active
    var isRecording: Bool

    // Animation states
    @State private var isBreathing = false
    @State private var isBlinking = false
    @State private var bounceOffset: CGFloat = 0

    // Pink colors
    private let cloudGradient = LinearGradient(
        colors: [
            Color(hex: "FFD1DC"),  // Soft pink
            Color(hex: "FFB6C1")   // Light pink
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let eyeColor = Color(hex: "6B5B7A")  // Soft purple
    private let blushColor = Color(hex: "FF8FAB")  // Cute pink blush

    var body: some View {
        ZStack {
            // Audio wave rings
            AudioWaveRings(audioLevel: $audioLevel, isRecording: isRecording)

            // Pulsing glow when recording
            if isRecording {
                Circle()
                    .fill(Color(hex: "FFB6C1").opacity(0.3))
                    .frame(width: 100 + CGFloat(audioLevel) * 25, height: 70 + CGFloat(audioLevel) * 18)
                    .blur(radius: 20)
            }

            // Cloud body - increased reactivity from 0.15 to 0.25
            CompactFluffyCloudShape(gradient: cloudGradient)
                .frame(width: 90, height: 65)
                .scaleEffect(1.0 + CGFloat(audioLevel) * 0.25)

            // Face
            VStack(spacing: 3) {
                // Eyes
                HStack(spacing: 20) {
                    CompactEyeView(isBlinking: isBlinking)
                    CompactEyeView(isBlinking: isBlinking)
                }

                // Rosy cheeks
                HStack(spacing: 32) {
                    Circle()
                        .fill(blushColor.opacity(0.4))
                        .frame(width: 12, height: 12)
                        .blur(radius: 3)
                    Circle()
                        .fill(blushColor.opacity(0.4))
                        .frame(width: 12, height: 12)
                        .blur(radius: 3)
                }
                .offset(y: -1)

                // Smile - bigger: 16x7 -> 24x12, stroke 2 -> 2.5
                CompactSmileShape()
                    .stroke(eyeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 24, height: 12)
            }
            .offset(y: -3)
        }
        .scaleEffect(isBreathing ? 1.03 : 1.0)
        .offset(y: bounceOffset)
        .onAppear {
            startAnimations()
        }
        .onChange(of: isRecording) { recording in
            if recording {
                startAnimations()
            }
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isBreathing = true
        }

        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            bounceOffset = -3
        }

        startBlinkingLoop()
    }

    private func startBlinkingLoop() {
        let delay = Double.random(in: 2.0...4.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isBlinking = false
                }
                startBlinkingLoop()
            }
        }
    }
}

// MARK: - Compact Fluffy Cloud Shape

struct CompactFluffyCloudShape: View {
    let gradient: LinearGradient

    var body: some View {
        ZStack {
            Ellipse()
                .fill(gradient)
                .frame(width: 70, height: 48)

            Circle().fill(gradient).frame(width: 35).offset(x: -28, y: -3)
            Circle().fill(gradient).frame(width: 38).offset(x: 26, y: -5)
            Circle().fill(gradient).frame(width: 28).offset(x: -18, y: -20)
            Circle().fill(gradient).frame(width: 30).offset(x: 14, y: -18)
            Circle().fill(gradient).frame(width: 32).offset(x: 0, y: -22)
            Circle().fill(gradient).frame(width: 28).offset(x: -22, y: 12)
            Circle().fill(gradient).frame(width: 30).offset(x: 20, y: 10)
        }
        .shadow(color: Color(hex: "FFB6C1").opacity(0.3), radius: 12, x: 0, y: 8)
    }
}

// MARK: - Compact Eye View

struct CompactEyeView: View {
    let isBlinking: Bool
    private let eyeColor = Color(hex: "6B5B7A")

    var body: some View {
        ZStack {
            if isBlinking {
                // Happy closed eye
                CompactClosedEyeShape()
                    .stroke(eyeColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 12, height: 6)
            } else {
                // Open eye
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 18, height: 18)
                        .shadow(color: Color.black.opacity(0.08), radius: 1, x: 0, y: 1)

                    Circle()
                        .fill(eyeColor)
                        .frame(width: 11, height: 11)
                        .offset(x: 0.5, y: 0.5)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .offset(x: -2.5, y: -3)

                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 3, height: 3)
                        .offset(x: 2.5, y: 2)
                }
            }
        }
    }
}

// MARK: - Compact Closed Eye Shape

struct CompactClosedEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY)
        )
        return path
    }
}

// MARK: - Compact Smile Shape

struct CompactSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 4)  // Bigger curve: +1 -> +4
        )
        return path
    }
}

// MARK: - Preview

#Preview("Recording") {
    ZStack {
        Color(hex: "FFF5F8")
        CompactCloudView(
            audioLevel: .constant(0.5),
            isRecording: true
        )
    }
    .frame(width: 200, height: 200)
}

#Preview("Idle") {
    ZStack {
        Color(hex: "FFF5F8")
        CompactCloudView(
            audioLevel: .constant(0.0),
            isRecording: false
        )
    }
    .frame(width: 200, height: 200)
}
