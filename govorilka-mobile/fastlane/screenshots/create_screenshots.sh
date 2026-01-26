#!/bin/bash
# iOS Screenshot Helper for Говорилка
# Run from govorilka-mobile directory

set -e

SCREENSHOTS_DIR="fastlane/screenshots"
LOCALES=("ru" "en-US")

# Color definitions
PINK='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${PINK}📱 iOS Screenshot Helper for Говорилка${NC}"
echo "======================================="
echo ""

# Required sizes for App Store
echo -e "${GREEN}Required screenshot sizes:${NC}"
echo "  • iPhone 6.7\" (15 Pro Max): 1290 x 2796 (REQUIRED)"
echo "  • iPhone 6.5\" (11 Pro Max): 1284 x 2778 (REQUIRED)"
echo ""

# Create directories
for locale in "${LOCALES[@]}"; do
    mkdir -p "$SCREENSHOTS_DIR/$locale"
    echo "✓ Directory ready: $SCREENSHOTS_DIR/$locale"
done

echo ""
echo -e "${GREEN}📸 Screenshots to capture (6 total):${NC}"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ #  │ File                  │ Content                           │"
echo "├─────────────────────────────────────────────────────────────────┤"
echo "│ 1  │ 01_recording.png      │ Main screen, record button        │"
echo "│ 2  │ 02_transcribing.png   │ Active recording with waveform    │"
echo "│ 3  │ 03_result.png         │ Completed transcription           │"
echo "│ 4  │ 04_history.png        │ History list with entries         │"
echo "│ 5  │ 05_pro_mode.png       │ Pro mode with photo attached      │"
echo "│ 6  │ 06_settings.png       │ Settings screen                   │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

echo -e "${GREEN}Text overlays (RU / EN):${NC}"
echo ""
echo "1. Говори. Записывается.     │ Speak. It Writes."
echo "2. Слова появляются мгновенно │ Words Appear Instantly"
echo "3. Готово. Копируй куда хочешь│ Done. Copy Anywhere"
echo "4. Все записи под рукой       │ All Recordings at Hand"
echo "5. Фото + голос = контекст    │ Photo + Voice = Context"
echo "6. Просто настроить           │ Easy to Set Up"
echo ""

# Check current status
echo -e "${YELLOW}Current status:${NC}"
echo ""
for locale in "${LOCALES[@]}"; do
    echo "📁 $locale/:"
    count=0
    for i in {1..6}; do
        case $i in
            1) file="01_recording.png" ;;
            2) file="02_transcribing.png" ;;
            3) file="03_result.png" ;;
            4) file="04_history.png" ;;
            5) file="05_pro_mode.png" ;;
            6) file="06_settings.png" ;;
        esac
        if [ -f "$SCREENSHOTS_DIR/$locale/$file" ]; then
            echo "   ✅ $file"
            ((count++))
        else
            echo "   ⬜ $file"
        fi
    done
    echo "   Progress: $count/6"
    echo ""
done

# Instructions for capturing
echo -e "${GREEN}📋 How to capture screenshots:${NC}"
echo ""
echo "Option 1: iOS Simulator (Recommended)"
echo "  1. Run app: npx expo start --ios"
echo "  2. Use Cmd+S in Simulator to save screenshot"
echo "  3. Rename and move to appropriate folder"
echo ""
echo "Option 2: Physical device"
echo "  1. Press Side + Volume Up buttons"
echo "  2. Transfer to Mac via AirDrop"
echo "  3. Rename and move to appropriate folder"
echo ""

# Check if ImageMagick is installed for resizing
if command -v convert &> /dev/null; then
    echo "✓ ImageMagick found - can resize screenshots"
    echo ""
    echo "To resize to 6.7\" size:"
    echo "  convert input.png -resize 1290x2796! output.png"
    echo ""
    echo "To resize all in folder:"
    echo "  for f in *.png; do convert \"\$f\" -resize 1290x2796! \"resized_\$f\"; done"
else
    echo -e "${YELLOW}⚠ ImageMagick not found. Install with: brew install imagemagick${NC}"
fi

echo ""
echo -e "${GREEN}📁 Place final screenshots in:${NC}"
echo "  Russian:  $SCREENSHOTS_DIR/ru/"
echo "  English:  $SCREENSHOTS_DIR/en-US/"
echo ""
echo "Naming: {order}_{screen_name}.png"
echo "Example: 01_recording.png, 02_transcribing.png"
echo ""

# Figma checklist
echo -e "${GREEN}🎨 Figma Design Checklist:${NC}"
echo ""
echo "  [ ] Create template 1290×2796 with gradient bg (#FFF5F8 → #FFE4EC)"
echo "  [ ] Add device frame (iPhone 15 Pro Max)"
echo "  [ ] Place app screenshots"
echo "  [ ] Add text overlays (SF Pro Display, Semibold)"
echo "  [ ] Apply effects (glow, shadows)"
echo "  [ ] Export PNG (no compression, sRGB)"
echo ""

# Color palette reminder
echo -e "${PINK}🎨 Color Palette:${NC}"
echo ""
echo "  Background:  #FFF5F8 → #FFE4EC"
echo "  Accent:      #FF69B4 → #FFB6C1"
echo "  Text:        #5D4E6D (on light) / #FFFFFF (on dark)"
echo ""
