#!/usr/bin/swift
// Script to generate cute small menu bar cloud icon
// Run with: swift generate_menubar_icon.swift

import AppKit
import Foundation

class MenuBarIconGenerator {

    func generateIcon(size: CGFloat, isRecording: Bool = false) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        let scale = size / 22.0
        let centerX = size / 2
        let centerY = size / 2

        // Draw small cute cloud
        drawSmallCloud(centerX: centerX, centerY: centerY, scale: scale, isRecording: isRecording)

        image.unlockFocus()

        image.isTemplate = !isRecording

        return image
    }

    private func drawSmallCloud(centerX: CGFloat, centerY: CGFloat, scale: CGFloat, isRecording: Bool) {
        let cloudColor = isRecording ? NSColor(red: 1, green: 0.56, blue: 0.64, alpha: 1) : NSColor.black
        let faceColor = isRecording ? NSColor.white : NSColor.white

        // Cloud body - smaller and more compact
        func drawPuff(x: CGFloat, y: CGFloat, radius: CGFloat) {
            let rect = NSRect(
                x: centerX + x * scale - radius * scale,
                y: centerY + y * scale - radius * scale,
                width: radius * 2 * scale,
                height: radius * 2 * scale
            )
            cloudColor.setFill()
            NSBezierPath(ovalIn: rect).fill()
        }

        // Main body - compact cloud shape
        drawPuff(x: 0, y: 0, radius: 4.5)
        drawPuff(x: -4, y: 0.5, radius: 3)
        drawPuff(x: 4, y: 0.5, radius: 3.2)
        drawPuff(x: -2, y: 3, radius: 2.5)
        drawPuff(x: 2, y: 3, radius: 2.8)
        drawPuff(x: 0, y: 3.5, radius: 2.8)
        drawPuff(x: -3.5, y: -2, radius: 2.5)
        drawPuff(x: 3.5, y: -2, radius: 2.5)

        // Cute face
        // Eyes - small dots
        let eyeSize: CGFloat = 1.5 * scale
        let eyeSpacing: CGFloat = 3 * scale
        let eyeY = centerY + 1 * scale

        faceColor.setFill()
        NSBezierPath(ovalIn: NSRect(
            x: centerX - eyeSpacing / 2 - eyeSize / 2,
            y: eyeY - eyeSize / 2,
            width: eyeSize,
            height: eyeSize
        )).fill()

        NSBezierPath(ovalIn: NSRect(
            x: centerX + eyeSpacing / 2 - eyeSize / 2,
            y: eyeY - eyeSize / 2,
            width: eyeSize,
            height: eyeSize
        )).fill()

        // Cute smile
        let smilePath = NSBezierPath()
        let smileWidth: CGFloat = 3 * scale
        let smileY = centerY - 1 * scale

        smilePath.move(to: NSPoint(x: centerX - smileWidth / 2, y: smileY))
        smilePath.curve(
            to: NSPoint(x: centerX + smileWidth / 2, y: smileY),
            controlPoint1: NSPoint(x: centerX - smileWidth / 4, y: smileY - 1.5 * scale),
            controlPoint2: NSPoint(x: centerX + smileWidth / 4, y: smileY - 1.5 * scale)
        )

        smilePath.lineWidth = 1 * scale
        smilePath.lineCapStyle = .round
        faceColor.setStroke()
        smilePath.stroke()

        // Blush for recording
        if isRecording {
            let blushColor = NSColor(red: 1, green: 0.42, blue: 0.54, alpha: 0.5)
            blushColor.setFill()
            NSBezierPath(ovalIn: NSRect(
                x: centerX - 4 * scale,
                y: eyeY - 2.5 * scale,
                width: 1.5 * scale,
                height: 1 * scale
            )).fill()
            NSBezierPath(ovalIn: NSRect(
                x: centerX + 2.5 * scale,
                y: eyeY - 2.5 * scale,
                width: 1.5 * scale,
                height: 1 * scale
            )).fill()
        }
    }
}

// MARK: - Main

func main() {
    let generator = MenuBarIconGenerator()

    // Regular icons
    let regularSizes: [(name: String, size: CGFloat)] = [
        ("menubar.png", 22),
        ("menubar@2x.png", 44),
        ("menubar@3x.png", 66)
    ]

    let regularBasePath = "Govorilka/Resources/Assets.xcassets/MenuBarIcon.imageset"

    for (name, size) in regularSizes {
        let image = generator.generateIcon(size: size, isRecording: false)
        let filePath = "\(regularBasePath)/\(name)"

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:])
        {
            do {
                try pngData.write(to: URL(fileURLWithPath: filePath))
                print("☁️ \(name)")
            } catch {
                print("Error: \(error)")
            }
        }
    }

    // Recording icons
    let recordingSizes: [(name: String, size: CGFloat)] = [
        ("menubar-recording.png", 22),
        ("menubar-recording@2x.png", 44),
        ("menubar-recording@3x.png", 66)
    ]

    let recordingBasePath = "Govorilka/Resources/Assets.xcassets/MenuBarIconRecording.imageset"

    for (name, size) in recordingSizes {
        let image = generator.generateIcon(size: size, isRecording: true)
        let filePath = "\(recordingBasePath)/\(name)"

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:])
        {
            do {
                try pngData.write(to: URL(fileURLWithPath: filePath))
                print("🎤 \(name)")
            } catch {
                print("Error: \(error)")
            }
        }
    }

    print("\n✨ Menu bar icons done!")
}

main()
