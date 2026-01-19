#!/usr/bin/env swift

import Cocoa

// Generate simple cloud menu bar icons
// Menu bar icons should be 18x18 (1x), 36x36 (2x), 54x54 (3x)

func createMenuBarIcon(size: CGFloat, isRecording: Bool) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Get graphics context
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Clear background
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let scale = size / 18.0
    let centerX = size / 2
    let centerY = size / 2

    // Simple fluffy cloud shape - 6 overlapping circles
    // Creates a recognizable cloud silhouette without face cutouts

    let cloudPath = CGMutablePath()

    // Bottom row - 3 circles forming the base
    let bottomY = centerY - 2 * scale
    let circleRadius = 4.0 * scale

    // Left bottom circle
    cloudPath.addEllipse(in: CGRect(
        x: centerX - 6 * scale - circleRadius / 2,
        y: bottomY - circleRadius / 2,
        width: circleRadius,
        height: circleRadius
    ))

    // Center bottom circle (slightly bigger)
    let centerBottomRadius = 5.0 * scale
    cloudPath.addEllipse(in: CGRect(
        x: centerX - centerBottomRadius / 2,
        y: bottomY - circleRadius / 2 - 1 * scale,
        width: centerBottomRadius,
        height: centerBottomRadius
    ))

    // Right bottom circle
    cloudPath.addEllipse(in: CGRect(
        x: centerX + 6 * scale - circleRadius / 2,
        y: bottomY - circleRadius / 2,
        width: circleRadius,
        height: circleRadius
    ))

    // Top row - 3 smaller circles forming the puffs
    let topY = centerY + 2 * scale
    let topRadius = 3.5 * scale

    // Left top puff
    cloudPath.addEllipse(in: CGRect(
        x: centerX - 4.5 * scale - topRadius / 2,
        y: topY - topRadius / 2,
        width: topRadius,
        height: topRadius
    ))

    // Center top puff (main bump)
    let mainPuffRadius = 4.5 * scale
    cloudPath.addEllipse(in: CGRect(
        x: centerX - mainPuffRadius / 2,
        y: topY + 1 * scale - mainPuffRadius / 2,
        width: mainPuffRadius,
        height: mainPuffRadius
    ))

    // Right top puff
    cloudPath.addEllipse(in: CGRect(
        x: centerX + 4.5 * scale - topRadius / 2,
        y: topY - topRadius / 2,
        width: topRadius,
        height: topRadius
    ))

    // Fill the cloud
    context.setFillColor(NSColor.black.cgColor)
    context.addPath(cloudPath)
    context.fillPath()

    // If recording, add small indicator dot in top-right corner
    if isRecording {
        let dotSize = 4.0 * scale
        context.fillEllipse(in: CGRect(
            x: size - dotSize - 1 * scale,
            y: size - dotSize - 1 * scale,
            width: dotSize,
            height: dotSize
        ))
    }

    image.unlockFocus()

    // Set as template image for proper menu bar rendering
    image.isTemplate = true

    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Error saving \(path): \(error)")
    }
}

// Generate icons
let basePath = "Govorilka/Resources/Assets.xcassets"

// Normal state
let sizes: [(CGFloat, String)] = [
    (18, "menubar.png"),
    (36, "menubar@2x.png"),
    (54, "menubar@3x.png")
]

for (size, filename) in sizes {
    let image = createMenuBarIcon(size: size, isRecording: false)
    savePNG(image, to: "\(basePath)/MenuBarIcon.imageset/\(filename)")
}

// Recording state
let recordingSizes: [(CGFloat, String)] = [
    (18, "menubar-recording.png"),
    (36, "menubar-recording@2x.png"),
    (54, "menubar-recording@3x.png")
]

for (size, filename) in recordingSizes {
    let image = createMenuBarIcon(size: size, isRecording: true)
    savePNG(image, to: "\(basePath)/MenuBarIconRecording.imageset/\(filename)")
}

print("Menu bar icons generated successfully!")
