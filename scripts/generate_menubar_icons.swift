#!/usr/bin/env swift

import Cocoa

// Generate minimalist menu bar icons
// Design: circle (ring) with colored dot in center
// - Idle: green dot
// - Recording: red dot
// Menu bar icons should be 18x18 (1x), 36x36 (2x), 54x54 (3x)

func createMenuBarIcon(size: CGFloat, isRecording: Bool) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Clear background
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let scale = size / 18.0
    let center = size / 2

    // Outer ring - black for visibility in both light/dark modes
    let ringRadius = 5.0 * scale
    let ringWidth = 1.0 * scale
    NSColor.black.setStroke()
    let ringPath = NSBezierPath(ovalIn: CGRect(
        x: center - ringRadius,
        y: center - ringRadius,
        width: ringRadius * 2,
        height: ringRadius * 2
    ))
    ringPath.lineWidth = ringWidth
    ringPath.stroke()

    // Center dot - colored
    let dotRadius = 2.0 * scale
    let dotColor = isRecording ? NSColor.systemRed : NSColor.systemGreen
    dotColor.setFill()
    let dotPath = NSBezierPath(ovalIn: CGRect(
        x: center - dotRadius,
        y: center - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    ))
    dotPath.fill()

    image.unlockFocus()

    // IMPORTANT: Not a template image - we want the colors to show
    image.isTemplate = false

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

// Normal state (green dot)
let sizes: [(CGFloat, String)] = [
    (18, "menubar.png"),
    (36, "menubar@2x.png"),
    (54, "menubar@3x.png")
]

for (size, filename) in sizes {
    let image = createMenuBarIcon(size: size, isRecording: false)
    savePNG(image, to: "\(basePath)/MenuBarIcon.imageset/\(filename)")
}

// Recording state (red dot)
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
print("Design: Circle with colored center dot")
print("- Idle: green dot")
print("- Recording: red dot")
