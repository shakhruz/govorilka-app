# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Говорилка is a minimalist macOS menu bar utility for voice-to-text transcription using Deepgram's Nova-2 API. The app captures audio, streams it via WebSocket to Deepgram, and provides real-time transcription with auto-copy/paste functionality.

## Build Commands

```bash
# Generate Xcode project (requires xcodegen: brew install xcodegen)
xcodegen generate

# Open in Xcode
open Govorilka.xcodeproj

# Build from command line
xcodebuild -project Govorilka.xcodeproj -scheme Govorilka -configuration Debug build
```

## Architecture

### Data Flow
1. **Global hotkey** (⌥+Space via KeyboardShortcuts) triggers `AppState.toggleRecording()`
2. `AppState` connects to Deepgram WebSocket, then starts `AudioService`
3. `AudioService` (AVAudioEngine) captures mic audio, converts to PCM 16-bit 16kHz mono
4. Audio chunks stream to `DeepgramService` via WebSocket
5. Transcripts (interim and final) flow back through delegate pattern to `AppState`
6. On stop: final text is copied to clipboard, optionally pasted via `PasteService`

### Key Components
- **AppState** (`ViewModels/AppState.swift`): Central state management, coordinates all services, implements delegate protocols for both AudioService and DeepgramService
- **DeepgramService** (`Services/DeepgramService.swift`): WebSocket connection to `wss://api.deepgram.com/v1/listen`, handles authentication and response parsing
- **AudioService** (`Services/AudioService.swift`): AVAudioEngine-based mic capture with format conversion (native → PCM 16-bit 16kHz)
- **PasteService** (`Services/PasteService.swift`): Clipboard operations and accessibility-based auto-paste (⌘V simulation)
- **StorageService** (`Services/StorageService.swift`): UserDefaults persistence for API key, settings, and history

### Delegate Pattern
Services communicate via delegate protocols (not Combine/async-await):
- `AudioServiceDelegate`: receives audio data chunks and errors
- `DeepgramServiceDelegate`: receives transcripts (interim/final), connection events, errors

### Menu Bar App Structure
- Uses SwiftUI `MenuBarExtra` with `.menuBarExtraStyle(.window)`
- No Dock icon, no main window - runs entirely from menu bar
- Views: `MenuBarView` (main popover) → `RecordingView`, `HistoryView`, `SettingsView`

## Dependencies

- **KeyboardShortcuts** (via SPM): Global hotkey registration
- **Deepgram API**: Requires API key from console.deepgram.com

## Requirements

- macOS 13.0+ (Ventura)
- Swift 5.9
- Xcode 15.0+

## Permissions

The app requires:
- **Microphone access**: For audio capture
- **Accessibility** (optional): For auto-paste feature (simulates ⌘V)
- **Screen Recording** (optional): For screenshot capture in feedback mode

Configured in `Govorilka/Govorilka.entitlements` and `Govorilka/Info.plist`.

## Design System

### Color Palette (Pink Theme)

The app uses a consistent pink color scheme. **Always use these exact colors:**

| Name | Hex | Usage |
|------|-----|-------|
| `pinkColor` | `#FF69B4` | Primary accent, buttons, icons, highlights |
| `lightPink` | `#FFB6C1` | Gradients (end color), secondary accents |
| `softPink` | `#FFF0F5` | Backgrounds, input fields, cards |
| `textColor` | `#5D4E6D` | Primary text (soft purple-gray) |

### Background Gradients

```swift
// Main background gradient
LinearGradient(
    colors: [Color(hex: "FFF5F8"), Color(hex: "FFE4EC")],
    startPoint: .top,
    endPoint: .bottom
)

// Button gradient
LinearGradient(
    colors: [pinkColor, lightPink],  // #FF69B4 → #FFB6C1
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### UI Components Style

- **Cards**: White background, cornerRadius 14, subtle shadow (black 0.04, radius 6)
- **Buttons**: Capsule shape with gradient, white text, shadow with pink tint
- **Input fields**: softPink background, cornerRadius 10, textColor for text
- **Icons**: SF Symbols, pinkColor for primary, textColor.opacity(0.5) for secondary

### Cloud Mascot Colors

```swift
// Cloud gradient
colors: [Color(hex: "FFD1DC"), Color(hex: "FFB6C1")]

// Eyes and smile
eyeColor: Color(hex: "6B5B7A")

// Blush cheeks
blushColor: Color(hex: "FF8FAB")

// Audio rings
ringColor: Color(hex: "FFB6C1")
```

### Typography

- Headers: System font, semibold weight
- Body: System font, regular weight
- Monospace: For hotkey labels (`.monospaced` design)
- Sizes: 14pt headers, 13pt body, 11pt captions, 10pt hints

### Important Design Rules

1. **Never change the pink color scheme** — it's the app's identity
2. **Use `Color(hex:)` extension** for all colors (defined in Theme.swift)
3. **Maintain soft, friendly aesthetic** — rounded corners, subtle shadows
4. **Text contrast**: Always use `textColor` (#5D4E6D) on light backgrounds
