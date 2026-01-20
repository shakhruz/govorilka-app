#!/usr/bin/swift
// Script to generate cute pink cloud app icons
// Run with: swift generate_app_icon.swift

import AppKit
import Foundation

// MARK: - Color Extension

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 181, 197) // Default pink
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1.0
        )
    }
}

// MARK: - Icon Generator

class IconGenerator {
    // Happy pink colors!
    let pinkLight = NSColor(hex: "FFB5C5")
    let pinkDark = NSColor(hex: "FF8FA3")
    let eyeColor = NSColor(hex: "5D4E6D")
    let blushColor = NSColor(hex: "FF6B8A")
    let backgroundColor = NSColor(hex: "FFF5F7")
    let sparkleColor = NSColor(hex: "FFE66D")

    func generateIcon(size: CGFloat) -> NSImage {
        // Create bitmap at exact pixel size (1x scale, not affected by Retina)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size),
            pixelsHigh: Int(size),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return NSImage(size: NSSize(width: size, height: size))
        }

        bitmap.size = NSSize(width: size, height: size)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

        guard NSGraphicsContext.current != nil else {
            NSGraphicsContext.restoreGraphicsState()
            return NSImage(size: NSSize(width: size, height: size))
        }

        // Background with soft pink gradient
        let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: size * 0.22, yRadius: size * 0.22)

        let gradient = NSGradient(
            colors: [NSColor.white, backgroundColor],
            atLocations: [0.0, 1.0],
            colorSpace: .sRGB
        )
        gradient?.draw(in: bgPath, angle: 90)

        let scale = size / 512.0
        let centerX = size / 2
        let centerY = size / 2 + (10 * scale)

        // Draw fluffy pink cloud
        drawFluffyCloud(centerX: centerX, centerY: centerY, scale: scale)

        // Draw happy face
        drawHappyFace(centerX: centerX, centerY: centerY, scale: scale)

        // Draw sparkles
        drawSparkles(centerX: centerX, centerY: centerY, scale: scale)

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(bitmap)
        return image
    }

    private func drawFluffyCloud(centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Scale factor to make cloud 75% bigger
        let cloudScale: CGFloat = 1.75

        func drawPuff(x: CGFloat, y: CGFloat, radius: CGFloat) {
            let rect = NSRect(
                x: centerX + x * cloudScale * scale - radius * cloudScale * scale,
                y: centerY + y * cloudScale * scale - radius * cloudScale * scale,
                width: radius * 2 * cloudScale * scale,
                height: radius * 2 * cloudScale * scale
            )
            let path = NSBezierPath(ovalIn: rect)

            // Pink shadow
            let shadow = NSShadow()
            shadow.shadowColor = pinkDark.withAlphaComponent(0.4)
            shadow.shadowBlurRadius = 20 * scale
            shadow.shadowOffset = NSSize(width: 0, height: -12 * scale)
            shadow.set()

            // Pink gradient fill
            pinkLight.setFill()
            path.fill()
        }

        func drawEllipse(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
            let rect = NSRect(
                x: centerX + x * cloudScale * scale - width * cloudScale * scale / 2,
                y: centerY + y * cloudScale * scale - height * cloudScale * scale / 2,
                width: width * cloudScale * scale,
                height: height * cloudScale * scale
            )
            let path = NSBezierPath(ovalIn: rect)
            pinkLight.setFill()
            path.fill()
        }

        // Main body: 200x140 -> 350x245
        drawEllipse(x: 0, y: 0, width: 200, height: 140)

        // Fluffy puffs (all scaled proportionally by 1.75)
        drawPuff(x: -84, y: 10, radius: 52)
        drawPuff(x: 80, y: 16, radius: 56)
        drawPuff(x: -56, y: 60, radius: 38)
        drawPuff(x: 44, y: 56, radius: 42)
        drawPuff(x: 0, y: 64, radius: 48)
        drawPuff(x: -64, y: -40, radius: 42)
        drawPuff(x: 60, y: -36, radius: 44)
    }

    private func drawHappyFace(centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Scale factor to match cloud size (75% bigger)
        let faceScale: CGFloat = 1.75
        let eyeSpacing: CGFloat = 64 * faceScale

        // Draw happy eyes
        drawHappyEye(x: centerX - eyeSpacing * scale / 2, y: centerY + 20 * faceScale * scale, scale: scale, faceScale: faceScale)
        drawHappyEye(x: centerX + eyeSpacing * scale / 2, y: centerY + 20 * faceScale * scale, scale: scale, faceScale: faceScale)

        // Draw big rosy cheeks
        drawBlush(centerX: centerX, centerY: centerY, scale: scale, faceScale: faceScale)

        // Draw big happy smile with tongue
        drawBigSmile(centerX: centerX, centerY: centerY - 25 * faceScale * scale, scale: scale, faceScale: faceScale)
    }

    private func drawHappyEye(x: CGFloat, y: CGFloat, scale: CGFloat, faceScale: CGFloat) {
        // White of eye
        let eyeRadius: CGFloat = 28 * faceScale * scale
        let eyeRect = NSRect(
            x: x - eyeRadius / 2,
            y: y - eyeRadius / 2,
            width: eyeRadius,
            height: eyeRadius
        )

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.1)
        shadow.shadowBlurRadius = 2 * scale
        shadow.shadowOffset = NSSize(width: 0, height: -1 * scale)
        shadow.set()

        NSColor.white.setFill()
        NSBezierPath(ovalIn: eyeRect).fill()

        NSShadow().set()

        // Pupil
        let pupilRadius: CGFloat = 18 * faceScale * scale
        let pupilRect = NSRect(
            x: x - pupilRadius / 2 + 1 * scale,
            y: y - pupilRadius / 2 - 1 * scale,
            width: pupilRadius,
            height: pupilRadius
        )
        eyeColor.setFill()
        NSBezierPath(ovalIn: pupilRect).fill()

        // Big sparkle highlight
        let highlight1Radius: CGFloat = 10 * faceScale * scale
        let highlight1Rect = NSRect(
            x: x - highlight1Radius / 2 - 4 * faceScale * scale,
            y: y - highlight1Radius / 2 + 5 * faceScale * scale,
            width: highlight1Radius,
            height: highlight1Radius
        )
        NSColor.white.setFill()
        NSBezierPath(ovalIn: highlight1Rect).fill()

        // Small sparkle
        let highlight2Radius: CGFloat = 5 * faceScale * scale
        let highlight2Rect = NSRect(
            x: x - highlight2Radius / 2 + 4 * faceScale * scale,
            y: y - highlight2Radius / 2 - 3 * faceScale * scale,
            width: highlight2Radius,
            height: highlight2Radius
        )
        NSColor.white.withAlphaComponent(0.8).setFill()
        NSBezierPath(ovalIn: highlight2Rect).fill()
    }

    private func drawBlush(centerX: CGFloat, centerY: CGFloat, scale: CGFloat, faceScale: CGFloat) {
        let blushSpacing: CGFloat = 100 * faceScale * scale / 2
        let blushSize: CGFloat = 24 * faceScale * scale
        let blushY = centerY + 5 * faceScale * scale

        // Left cheek
        let leftBlushRect = NSRect(
            x: centerX - blushSpacing - blushSize / 2,
            y: blushY - blushSize / 2,
            width: blushSize,
            height: blushSize
        )
        blushColor.withAlphaComponent(0.45).setFill()
        NSBezierPath(ovalIn: leftBlushRect).fill()

        // Right cheek
        let rightBlushRect = NSRect(
            x: centerX + blushSpacing - blushSize / 2,
            y: blushY - blushSize / 2,
            width: blushSize,
            height: blushSize
        )
        NSBezierPath(ovalIn: rightBlushRect).fill()
    }

    private func drawBigSmile(centerX: CGFloat, centerY: CGFloat, scale: CGFloat, faceScale: CGFloat) {
        // Big happy smile
        let smilePath = NSBezierPath()
        let smileWidth: CGFloat = 40 * faceScale * scale
        let smileHeight: CGFloat = 20 * faceScale * scale

        smilePath.move(to: NSPoint(x: centerX - smileWidth / 2, y: centerY + smileHeight / 3))
        smilePath.curve(
            to: NSPoint(x: centerX + smileWidth / 2, y: centerY + smileHeight / 3),
            controlPoint1: NSPoint(x: centerX - smileWidth / 4, y: centerY - smileHeight),
            controlPoint2: NSPoint(x: centerX + smileWidth / 4, y: centerY - smileHeight)
        )

        smilePath.lineWidth = 3.5 * faceScale * scale
        smilePath.lineCapStyle = .round
        eyeColor.setStroke()
        smilePath.stroke()

        // Cute tongue
        let tongueRect = NSRect(
            x: centerX - 8 * faceScale * scale,
            y: centerY - smileHeight / 2 - 4 * faceScale * scale,
            width: 16 * faceScale * scale,
            height: 10 * faceScale * scale
        )
        pinkDark.setFill()
        NSBezierPath(ovalIn: tongueRect).fill()
    }

    private func drawSparkles(centerX: CGFloat, centerY: CGFloat, scale: CGFloat) {
        // Scale factor to match cloud size (75% bigger)
        let sparkleScale: CGFloat = 1.75

        // Draw star sparkles around the cloud
        func drawStar(x: CGFloat, y: CGFloat, size: CGFloat, color: NSColor) {
            let starPath = NSBezierPath()
            let cx = centerX + x * sparkleScale * scale
            let cy = centerY + y * sparkleScale * scale
            let s = size * sparkleScale * scale

            // Simple 4-point star
            starPath.move(to: NSPoint(x: cx, y: cy + s))
            starPath.line(to: NSPoint(x: cx + s * 0.3, y: cy + s * 0.3))
            starPath.line(to: NSPoint(x: cx + s, y: cy))
            starPath.line(to: NSPoint(x: cx + s * 0.3, y: cy - s * 0.3))
            starPath.line(to: NSPoint(x: cx, y: cy - s))
            starPath.line(to: NSPoint(x: cx - s * 0.3, y: cy - s * 0.3))
            starPath.line(to: NSPoint(x: cx - s, y: cy))
            starPath.line(to: NSPoint(x: cx - s * 0.3, y: cy + s * 0.3))
            starPath.close()

            color.setFill()
            starPath.fill()
        }

        // Yellow sparkles - positioned relative to bigger cloud
        drawStar(x: -75, y: 55, size: 12, color: sparkleColor)
        drawStar(x: 70, y: 60, size: 10, color: sparkleColor)
        drawStar(x: 85, y: 0, size: 8, color: sparkleColor)

        // Pink heart - positioned relative to bigger cloud
        let heartX = centerX - 80 * sparkleScale * scale
        let heartY = centerY - 10 * sparkleScale * scale
        let heartSize: CGFloat = 10 * sparkleScale * scale

        let heartPath = NSBezierPath()
        heartPath.move(to: NSPoint(x: heartX, y: heartY + heartSize * 0.3))
        heartPath.curve(
            to: NSPoint(x: heartX, y: heartY + heartSize),
            controlPoint1: NSPoint(x: heartX - heartSize * 0.5, y: heartY + heartSize * 0.3),
            controlPoint2: NSPoint(x: heartX - heartSize * 0.5, y: heartY + heartSize)
        )
        heartPath.curve(
            to: NSPoint(x: heartX, y: heartY),
            controlPoint1: NSPoint(x: heartX, y: heartY + heartSize * 0.7),
            controlPoint2: NSPoint(x: heartX, y: heartY)
        )
        heartPath.curve(
            to: NSPoint(x: heartX, y: heartY + heartSize),
            controlPoint1: NSPoint(x: heartX, y: heartY),
            controlPoint2: NSPoint(x: heartX + heartSize * 0.5, y: heartY + heartSize)
        )
        heartPath.curve(
            to: NSPoint(x: heartX, y: heartY + heartSize * 0.3),
            controlPoint1: NSPoint(x: heartX + heartSize * 0.5, y: heartY + heartSize * 0.3),
            controlPoint2: NSPoint(x: heartX, y: heartY + heartSize * 0.3)
        )

        blushColor.withAlphaComponent(0.7).setFill()
        heartPath.fill()
    }
}

// MARK: - Main

func main() {
    let generator = IconGenerator()
    let basePath = "Govorilka/Resources/Assets.xcassets/AppIcon.appiconset"

    let sizes: [(name: String, size: CGFloat)] = [
        ("icon_16_16.png", 16),
        ("icon_16_16@2x.png", 32),
        ("icon_32_32.png", 32),
        ("icon_32_32@2x.png", 64),
        ("icon_128_128.png", 128),
        ("icon_128_128@2x.png", 256),
        ("icon_256_256.png", 256),
        ("icon_256_256@2x.png", 512),
        ("icon_512_512.png", 512),
        ("icon_512_512@2x.png", 1024)
    ]

    for (name, size) in sizes {
        let image = generator.generateIcon(size: size)
        let filePath = "\(basePath)/\(name)"

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:])
        {
            do {
                try pngData.write(to: URL(fileURLWithPath: filePath))
                print("✨ Generated: \(name) (\(Int(size))x\(Int(size)))")
            } catch {
                print("Error writing \(name): \(error)")
            }
        }
    }

    print("\n🎀 Cute pink app icons generated!")
}

main()
