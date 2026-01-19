import SwiftUI

/// Adorable feminine cloud character with pink accents
struct SmilingCloudView: View {
    // Animation states
    @State private var isBreathing = false
    @State private var isBlinking = false
    @State private var hasAppeared = false
    @State private var wobbleAngle: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var sparkleOpacity: Double = 0.5

    // Soft feminine pink colors
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
    private let bowColor = Color(hex: "FF69B4")  // Hot pink bow

    var body: some View {
        ZStack {
            // Fluffy cloud body
            FluffyCloudShape(gradient: cloudGradient)
                .frame(width: 140, height: 100)

            // Cute bow on top!
            BowView(color: bowColor)
                .offset(x: 35, y: -45)
                .scaleEffect(0.7)

            // Face
            VStack(spacing: 4) {
                // Cute eyes with eyelashes!
                HStack(spacing: 30) {
                    FeminineEyeView(isBlinking: isBlinking, sparkleOpacity: sparkleOpacity)
                    FeminineEyeView(isBlinking: isBlinking, sparkleOpacity: sparkleOpacity)
                }

                // Rosy cheeks
                HStack(spacing: 48) {
                    Circle()
                        .fill(blushColor.opacity(0.45))
                        .frame(width: 18, height: 18)
                        .blur(radius: 4)
                    Circle()
                        .fill(blushColor.opacity(0.45))
                        .frame(width: 18, height: 18)
                        .blur(radius: 4)
                }
                .offset(y: -2)

                // Sweet smile
                SweetSmileView()
            }
            .offset(y: -5)

            // Sparkles and hearts
            DecorationsView(opacity: sparkleOpacity)
        }
        .scaleEffect(isBreathing ? 1.04 : 1.0)
        .scaleEffect(hasAppeared ? 1.0 : 0.5)
        .rotationEffect(.degrees(wobbleAngle))
        .offset(y: bounceOffset)
        .opacity(hasAppeared ? 1.0 : 0.0)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            hasAppeared = true
        }

        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isBreathing = true
        }

        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            wobbleAngle = 2.5
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            bounceOffset = -2
        }

        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            sparkleOpacity = 1.0
        }

        startBlinkingLoop()
    }

    private func startBlinkingLoop() {
        let delay = Double.random(in: 2.5...4.5)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isBlinking = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isBlinking = false
                }
                startBlinkingLoop()
            }
        }
    }
}

// MARK: - Fluffy Cloud Shape

struct FluffyCloudShape: View {
    let gradient: LinearGradient

    var body: some View {
        ZStack {
            Ellipse()
                .fill(gradient)
                .frame(width: 100, height: 70)

            Circle().fill(gradient).frame(width: 50).offset(x: -40, y: -5)
            Circle().fill(gradient).frame(width: 54).offset(x: 38, y: -8)
            Circle().fill(gradient).frame(width: 36).offset(x: -26, y: -28)
            Circle().fill(gradient).frame(width: 40).offset(x: 20, y: -26)
            Circle().fill(gradient).frame(width: 46).offset(x: 0, y: -30)
            Circle().fill(gradient).frame(width: 40).offset(x: -30, y: 18)
            Circle().fill(gradient).frame(width: 42).offset(x: 28, y: 16)
        }
        .shadow(color: Color(hex: "FFB6C1").opacity(0.4), radius: 20, x: 0, y: 12)
    }
}

// MARK: - Bow View

struct BowView: View {
    let color: Color

    var body: some View {
        ZStack {
            // Left loop
            Ellipse()
                .fill(color)
                .frame(width: 20, height: 14)
                .rotationEffect(.degrees(-30))
                .offset(x: -10)

            // Right loop
            Ellipse()
                .fill(color)
                .frame(width: 20, height: 14)
                .rotationEffect(.degrees(30))
                .offset(x: 10)

            // Center knot
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: 10, height: 10)

            // Ribbons
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.8))
                .frame(width: 6, height: 12)
                .rotationEffect(.degrees(-15))
                .offset(x: -4, y: 10)

            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.8))
                .frame(width: 6, height: 12)
                .rotationEffect(.degrees(15))
                .offset(x: 4, y: 10)
        }
    }
}

// MARK: - Feminine Eye View

struct FeminineEyeView: View {
    let isBlinking: Bool
    var sparkleOpacity: Double = 0.5

    private let eyeColor = Color(hex: "6B5B7A")

    var body: some View {
        ZStack {
            if isBlinking {
                // Happy closed eye with eyelashes
                VStack(spacing: 0) {
                    // Eyelashes
                    HStack(spacing: 3) {
                        ForEach(0..<3) { i in
                            Capsule()
                                .fill(eyeColor)
                                .frame(width: 1.5, height: 5)
                                .rotationEffect(.degrees(Double(i - 1) * 20))
                        }
                    }
                    .offset(y: 3)

                    // Closed eye arc
                    HappyClosedEyeShape()
                        .stroke(eyeColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 16, height: 8)
                }
            } else {
                ZStack {
                    // White of eye
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

                    // Pupil
                    Circle()
                        .fill(eyeColor)
                        .frame(width: 16, height: 16)
                        .offset(x: 1, y: 1)

                    // Main sparkle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .offset(x: -4, y: -5)

                    // Small sparkle
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 4, height: 4)
                        .offset(x: 4, y: 3)

                    // Eyelashes on top
                    EyelashesView()
                        .offset(y: -12)
                }
            }
        }
    }
}

// MARK: - Eyelashes View

struct EyelashesView: View {
    private let eyeColor = Color(hex: "6B5B7A")

    var body: some View {
        HStack(spacing: 4) {
            Capsule()
                .fill(eyeColor)
                .frame(width: 1.5, height: 6)
                .rotationEffect(.degrees(-25))
            Capsule()
                .fill(eyeColor)
                .frame(width: 1.5, height: 7)
                .rotationEffect(.degrees(-10))
            Capsule()
                .fill(eyeColor)
                .frame(width: 1.5, height: 8)
            Capsule()
                .fill(eyeColor)
                .frame(width: 1.5, height: 7)
                .rotationEffect(.degrees(10))
            Capsule()
                .fill(eyeColor)
                .frame(width: 1.5, height: 6)
                .rotationEffect(.degrees(25))
        }
    }
}

// MARK: - Happy Closed Eye Shape

struct HappyClosedEyeShape: Shape {
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

// MARK: - Sweet Smile View

struct SweetSmileView: View {
    private let smileColor = Color(hex: "6B5B7A")

    var body: some View {
        // Simple cute smile
        SweetSmileShape()
            .stroke(smileColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: 22, height: 10)
    }
}

// MARK: - Sweet Smile Shape

struct SweetSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 2)
        )
        return path
    }
}

// MARK: - Decorations View

struct DecorationsView: View {
    var opacity: Double

    var body: some View {
        ZStack {
            // Hearts
            Image(systemName: "heart.fill")
                .font(.system(size: 8))
                .foregroundColor(Color(hex: "FF69B4"))
                .offset(x: -62, y: -30)
                .opacity(opacity * 0.7)

            Image(systemName: "heart.fill")
                .font(.system(size: 6))
                .foregroundColor(Color(hex: "FFB6C1"))
                .offset(x: 58, y: -38)
                .opacity(opacity * 0.8)

            // Sparkles
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "FFD700"))
                .offset(x: -55, y: 5)
                .opacity(opacity * 0.6)

            Image(systemName: "sparkle")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(Color(hex: "FF69B4"))
                .offset(x: 62, y: -5)
                .opacity(opacity)

            // Star
            Image(systemName: "star.fill")
                .font(.system(size: 6))
                .foregroundColor(Color(hex: "FFD700"))
                .offset(x: -48, y: -42)
                .opacity(opacity * 0.5)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SmilingCloudView()

        Text("Привет! Я Говорилка")
            .font(.title2)
            .fontWeight(.semibold)
    }
    .padding(40)
    .background(Color(hex: "FFF5F8"))
}
