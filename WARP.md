# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

Govorilka is a macOS 13+ SwiftUI menu bar app that streams microphone audio to Deepgram over WebSocket, receives real‑time transcripts (Russian/English), copies the final text to the clipboard, and can optionally paste it into the active app. The app is structured as a single `AppState` view model with SwiftUI views for UI and small focused services for audio capture, networking, clipboard/paste, and persistence.

The Xcode project is generated from `project.yml` using XcodeGen. The primary target is `Govorilka` (macOS app) with a dependency on the `KeyboardShortcuts` Swift package.

## Common commands and workflows

### Initial setup

- Install XcodeGen (if not already available):

```bash
brew install xcodegen
```

- Generate the Xcode project from `project.yml`:

```bash
xcodegen generate
```

- Open the generated project in Xcode:

```bash
open Govorilka.xcodeproj
```

### Build and run

Most development is expected to happen in Xcode:

- Select the `Govorilka` scheme and build/run from Xcode (`⌘R`).
- Ensure the deployment target is macOS 13.0+ (configured via `project.yml`).

For automation/CI you can use standard `xcodebuild` invocations, for example:

```bash
xcodebuild \
  -project Govorilka.xcodeproj \
  -scheme Govorilka \
  -configuration Release \
  build
```

### Tests

There is no explicit test target or test runner script in this repository at the moment. To add tests:

- Create a test target in Xcode and add your test files there.
- Run tests via Xcode (`⌘U`) or using the usual `xcodebuild ... test` commands once a test scheme exists.

### Linting and formatting

No external Swift linting/formatting tools are configured (e.g. no SwiftLint config). Rely on:

- The Swift compiler and Xcode diagnostics for basic correctness.
- Xcode's built‑in formatting (`Editor → Structure → Re‑Indent`, etc.).

If you introduce a linter (e.g. SwiftLint), prefer adding its configuration file at the repo root and documenting the corresponding CLI in this section.

## Architecture overview

### Entry point and UI composition

- `Govorilka/GovorilkaApp.swift`
  - Declares `@main struct GovorilkaApp: App`.
  - Creates a single `@StateObject private var appState = AppState()` that is passed down into the view hierarchy.
  - Uses `MenuBarExtra` as the only scene: there is no main window; the UI lives entirely in the menu bar popover.
  - The menu bar icon and its color reflect `appState.isRecording`.

- `Govorilka/Views/MenuBarView.swift`
  - Root content of the popover.
  - Always shows `RecordingView` at the top, then a segmented control that switches between `HistoryView` and `SettingsView`.
  - Footer shows the app version label and an explicit “Quit” button calling `NSApplication.shared.terminate(nil)`.
  - Displays global error alerts bound to `appState.showError` / `appState.errorMessage`.

### State management (AppState)

- `Govorilka/ViewModels/AppState.swift` is the central orchestrator and single source of truth.
  - Publishes UI state: recording flags, current/interim transcript, history list, error state, connection state, and settings (`apiKey`, `autoPasteEnabled`, `hasAccessibilityPermission`).
  - Owns service instances: `AudioService`, `DeepgramService`, `PasteService.shared`, `StorageService.shared`.
  - On init:
    - Loads persisted settings and history from `StorageService`.
    - Queries accessibility permission status via `PasteService`.
    - Registers a global keyboard shortcut (`KeyboardShortcuts.Name.toggleRecording`) to call `toggleRecording()`.

- Recording lifecycle methods:
  - `toggleRecording()` delegates to `startRecording()` / `stopRecording()`.
  - `startRecording()`:
    - Verifies that an API key is present in storage; otherwise surfaces a user‑facing error.
    - Asynchronously requests microphone permission via `AudioService.requestPermission()`.
    - On success, sets `isConnecting` and establishes a Deepgram WebSocket connection via `deepgramService.connect()`.
  - `stopRecording()`:
    - Stops the audio engine and obtains the recording duration from `AudioService.stopRecording()`.
    - Sends an end‑of‑stream signal to Deepgram and disconnects.
    - Collapses `currentTranscript` and `interimTranscript` into a final text block.
    - Persists a new `TranscriptEntry` into in‑memory `history` and `StorageService`.
    - Copies text to the clipboard, and if `autoPasteEnabled && hasAccessibilityPermission` also triggers an auto‑paste.
    - Resets recording/connection and transcript state.

- Delegation:
  - Conforms to `AudioServiceDelegate` and `DeepgramServiceDelegate`.
  - For each audio buffer received, forwards raw PCM data to `DeepgramService.sendAudio`.
  - Handles Deepgram transcripts by appending final segments to `currentTranscript` or updating `interimTranscript` for live preview.
  - On any service error, shows a user‑visible error message and stops recording cleanly.

### Services layer

All services are small, focused, and mostly UI‑agnostic. When extending behavior, prefer adding capabilities here and keeping `AppState` as orchestration glue.

- `Govorilka/Services/AudioService.swift`
  - Wraps `AVAudioEngine` to capture microphone audio.
  - Ensures output is PCM 16‑bit, 16 kHz, mono (Deepgram‑compatible) via `AVAudioConverter` in `processAudioBuffer`.
  - Streams converted audio chunks to its delegate as `Data`.
  - Tracks recording duration internally (`recordingStartTime`), returning it from `stopRecording()`.
  - Central place to modify audio format or buffering strategy if Deepgram requirements change.

- `Govorilka/Services/DeepgramService.swift`
  - Manages a `URLSessionWebSocketTask` to Deepgram's `wss://api.deepgram.com/v1/listen` endpoint.
  - Constructs query parameters for language autodetection (`language=multi`), model (`nova-2`), punctuation, interim results, and audio format.
  - Reads the API key from `StorageService` and injects it as an `Authorization: Token <key>` header.
  - Continuously receives WebSocket messages, decoding them into lightweight internal models (`DeepgramResponse`, `ChannelResult`, `Alternative`).
  - Extracts the first transcript alternative and its `is_final` flag and forwards them to its delegate.
  - Treats parse errors as non‑fatal (many WebSocket messages are metadata) and simply logs them.
  - Exposes `finishStream()` to signal the end of the audio stream and `disconnect()` to close the socket.

- `Govorilka/Services/PasteService.swift`
  - Singleton (`PasteService.shared`) handling clipboard writes and optional “simulate Cmd+V” behavior.
  - Uses `NSPasteboard.general` for copy operations.
  - Implements `hasAccessibilityPermission()` / `requestAccessibilityPermission()` via `AXIsProcessTrustedWithOptions`.
  - Encapsulates a CGEvent‑based implementation of programmatic `⌘V`; if you change how auto‑paste works, do it here.

- `Govorilka/Services/StorageService.swift`
  - Singleton that wraps `UserDefaults.standard`.
  - Persists:
    - Deepgram API key.
    - Auto‑paste enabled flag.
    - Maximum history length (default 50).
    - Onboarding/completion state.
    - Serialized `[TranscriptEntry]` history.
  - Centralizes history trimming: `saveHistory` keeps only the most recent `maxHistoryCount` entries.
  - `resetAllSettings()` clears all app‑specific keys.

### Data model

- `Govorilka/Models/TranscriptEntry.swift`
  - Codable, Equatable, Identifiable value type representing one transcript in history.
  - Stores `id`, `text`, `timestamp`, and `duration` (seconds).
  - Provides display helpers:
    - `formattedTimestamp` (localized Russian strings for “today”, “yesterday”, otherwise `d MMM, HH:mm`).
    - `formattedDuration` as `mm:ss` or `N сек`.
    - `preview` limited to 100 characters, used in the history list.
  - Includes a few static `sample` entries intended for SwiftUI previews.

### Views

Views are thin; they bind to `AppState` and use its methods instead of duplicating logic.

- `RecordingView`
  - Shows recording status indicator with pulsing animation while recording.
  - Provides the main record/stop button that calls `appState.toggleRecording()`.
  - Displays the active keyboard shortcut via `KeyboardShortcuts.Recorder`.
  - Shows the live transcript (`currentTranscript` + `interimTranscript`) with text selection enabled.

- `HistoryView` / `HistoryRow`
  - Renders either an empty state or a `List` of `TranscriptEntry` items from `appState.history`.
  - Supports context menu actions to copy or delete a specific entry.
  - Exposes a “Clear” action with confirmation, which calls `appState.clearHistory()`.

- `SettingsView`
  - Sections for:
    - Deepgram API key entry and persistence via `appState.saveApiKey`.
    - Keyboard shortcut configuration using `KeyboardShortcuts.Recorder`.
    - Auto‑paste toggle bound to `appState.autoPasteEnabled` via `saveAutoPaste`, with accessibility permission status and a "Настроить" button that calls `appState.requestAccessibility()`.
    - Simple “About” section with links to Deepgram and the GitHub repo.
  - On appear, syncs its local `apiKeyInput` from `appState.apiKey` and refreshes accessibility status.

### Project configuration (XcodeGen)

- `project.yml`
  - Defines a single `Govorilka` application target for macOS with:
    - Bundle ID prefix `com.skylineyoga` and product bundle ID `com.skylineyoga.govorilka`.
    - Deployment target macOS 13.0 and Swift version 5.9.
    - Hardened runtime enabled and entitlements/Info.plist wired to files under `Govorilka/`.
  - Declares a Swift Package dependency on `KeyboardShortcuts` (from `https://github.com/sindresorhus/KeyboardShortcuts`, version `from: "2.0.0"`).

## Notes for Warp agents

- The app’s runtime behavior is tightly coupled to macOS permissions (microphone, accessibility) and Deepgram networking; when debugging, pay attention to the interactions between `AppState`, `AudioService`, `DeepgramService`, and `PasteService` rather than modifying views first.
- When introducing new features that affect recording or transcript flow, prefer:
  - Adding capabilities in services (`AudioService`, `DeepgramService`, `StorageService`, `PasteService`).
  - Keeping `AppState` as the single orchestrator that glues services to the UI.
  - Keeping SwiftUI views declarative and free of side effects beyond calling `AppState` methods.