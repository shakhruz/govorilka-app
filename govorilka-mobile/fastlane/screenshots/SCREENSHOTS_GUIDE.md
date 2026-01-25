# iOS Screenshots Guide — Говорилка

## Required Sizes

| Device | Resolution | Required |
|--------|-----------|----------|
| iPhone 6.7" (15 Pro Max) | 1290 x 2796 | ✅ Yes |
| iPhone 6.5" (11 Pro Max) | 1284 x 2778 | ✅ Yes |
| iPhone 5.5" (8 Plus) | 1242 x 2208 | Optional |
| iPad Pro 12.9" (6th gen) | 2048 x 2732 | Optional |

## Screenshots List

### 1. Main Recording Screen
- **File:** `01_recording.png`
- **Text overlay:** "Нажмите и говорите" / "Tap and speak"
- **Content:** Main screen with record button, cloud mascot visible
- **State:** Ready to record (pink button prominent)

### 2. Transcription in Progress
- **File:** `02_transcribing.png`
- **Text overlay:** "Текст появляется мгновенно" / "Text appears instantly"
- **Content:** Active recording with waveform, interim text showing
- **State:** Recording active (animated ring around button)

### 3. History View
- **File:** `03_history.png`
- **Text overlay:** "Все записи под рукой" / "All recordings at hand"
- **Content:** History list with several transcription entries
- **State:** Showing date groupings, text previews

### 4. Settings
- **File:** `04_settings.png`
- **Text overlay:** "Просто настроить" / "Easy to configure"
- **Content:** Settings screen with API key field, cleanup toggle
- **State:** API key entered (masked), cleanup enabled

### 5. Pro Mode with Photo
- **File:** `05_pro_mode.png`
- **Text overlay:** "Фото + голос = контекст" / "Photo + voice = context"
- **Content:** Recording with photo attached
- **State:** Photo thumbnail visible alongside transcription

### 6. Text Cleanup Feature
- **File:** `06_cleanup.png`
- **Text overlay:** "Удаляем слова-паразиты" / "Removing filler words"
- **Content:** Before/after comparison or settings toggle
- **State:** Shows cleanup in action

## Design Guidelines

### Background
```
Pink gradient: #FFF5F8 → #FFE4EC
```

### Text Overlays
- Font: SF Pro Display, Semibold
- Size: 72pt for Russian, 64pt for English
- Color: #5D4E6D (textColor) or white on dark areas
- Position: Top 15% of image, centered

### Device Frame
- Use Apple's official Device Art or Fastlane's frameit
- Frame color: Silver or Space Gray

### File Naming Convention
```
{locale}/{order}_{screen_name}.png

Examples:
ru/01_recording.png
en-US/01_recording.png
```

## Figma Template

Create screenshots in Figma with:
1. Frame size matching device resolution
2. Screenshot layer (actual app screenshot)
3. Text overlay layer with gradient background
4. Device frame layer (optional, can use frameit)

## Automation with Fastlane

```bash
# Generate frames
cd govorilka-mobile
fastlane frameit

# Upload screenshots
fastlane screenshots
```
