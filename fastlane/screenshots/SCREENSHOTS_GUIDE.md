# macOS Screenshots Guide — Говорилка для Mac

## Required Sizes

| Display | Resolution | Required |
|---------|-----------|----------|
| Mac | 2880 x 1800 | ✅ Yes |
| Mac (alternative) | 1280 x 800 | Optional |

## Screenshots List

### 1. Menu Bar with Popover
- **File:** `01_menubar.png`
- **Text overlay:** "Живёт в меню-баре" / "Lives in menu bar"
- **Content:** Menu bar icon with popover open, showing main UI
- **State:** App open, ready to record

### 2. Floating Recording Window
- **File:** `02_floating.png`
- **Text overlay:** "Диктуйте в любое приложение" / "Dictate into any app"
- **Content:** Floating window with waveform over a text editor
- **State:** Recording active, waveform animating

### 3. Auto-paste in Action
- **File:** `03_autopaste.png`
- **Text overlay:** "Текст вставляется сам" / "Text auto-inserts"
- **Content:** Text editor with freshly pasted transcription
- **State:** Cursor at end of inserted text

### 4. History View
- **File:** `04_history.png`
- **Text overlay:** "История всегда рядом" / "History always nearby"
- **Content:** Popover showing history tab with entries
- **State:** Multiple entries with timestamps

### 5. Hotkey Settings
- **File:** `05_hotkeys.png`
- **Text overlay:** "Ваш хоткей — ваши правила" / "Your hotkey, your rules"
- **Content:** Settings view with hotkey configuration
- **State:** Showing available hotkey options

## Design Guidelines

### Desktop Background
- Use a clean, minimal desktop wallpaper
- Light color that complements pink theme
- No distracting icons or windows

### App Context
- Show real app windows (VS Code, Notes, TextEdit, etc.)
- Demonstrate the utility in real workflow

### Text Overlays
- Font: SF Pro Display, Semibold
- Size: 48pt
- Color: #5D4E6D or white
- Position: Top of screenshot, with subtle gradient background

### File Naming Convention
```
{locale}/{order}_{screen_name}.png

Examples:
ru/01_menubar.png
en-US/01_menubar.png
```

## Recording Screenshots

### Menu Bar Screenshot
1. Click menu bar icon to open popover
2. Use Cmd+Shift+4, then Space to capture window
3. Or use full screenshot and crop

### Floating Window
1. Start recording (triggers floating window)
2. Position over desired app
3. Screenshot the composition

### Auto-paste Demo
1. Open text editor
2. Complete a recording
3. Screenshot immediately after paste

## Automation

```bash
# Generate frames (if using frameit)
cd /path/to/govorilka
fastlane frameit

# Upload to App Store Connect
fastlane mac screenshots
```
