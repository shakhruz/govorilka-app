import SwiftUI

/// Centralized theme colors for Govorilka app
/// Use these constants instead of hardcoding Color(hex:) values
enum Theme {

    // MARK: - Primary Colors

    /// Main pink accent color (Hot Pink) - #FF69B4
    static let pink = Color(hex: "FF69B4")

    /// Light pink for backgrounds and accents - #FFB6C1
    static let lightPink = Color(hex: "FFB6C1")

    /// Very soft pink for backgrounds - #FFF5F8
    static let softPink = Color(hex: "FFF5F8")

    /// Soft pink background variant - #FFF0F5
    static let softPinkBackground = Color(hex: "FFF0F5")

    // MARK: - Text Colors

    /// Primary text color (Purple/Gray) - #5D4E6D
    static let text = Color(hex: "5D4E6D")

    /// Secondary text color (lighter)
    static let textSecondary = Color(hex: "5D4E6D").opacity(0.6)

    // MARK: - Cloud Character Colors

    /// Eye color for cloud character - #6B5B7A
    static let eyeColor = Color(hex: "6B5B7A")

    /// Blush color for cloud cheeks - #FF8FAB
    static let blushColor = Color(hex: "FF8FAB")

    /// Bow color (same as pink) - #FF69B4
    static let bowColor = pink

    /// Cloud gradient colors
    static let cloudGradient = [
        Color(hex: "FFD1DC"),  // Soft pink
        Color(hex: "FFB6C1")   // Light pink
    ]

    // MARK: - Accent Colors

    /// Purple accent - #9B6BFF
    static let purpleAccent = Color(hex: "9B6BFF")

    /// Coral accent - #FF7B7B
    static let coralAccent = Color(hex: "FF7B7B")

    /// Recording red indicator - #FF6B6B
    static let recordingRed = Color(hex: "FF6B6B")

    /// Gold/Yellow for sparkles - #FFD700
    static let gold = Color(hex: "FFD700")

    // MARK: - Background Colors

    /// Neutral gray background - #F0F0F0
    static let grayBackground = Color(hex: "F0F0F0")

    // MARK: - Gradients

    /// Main background gradient
    static let backgroundGradient = LinearGradient(
        colors: [softPink, .white],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Cloud shadow color
    static let cloudShadow = lightPink.opacity(0.4)
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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
