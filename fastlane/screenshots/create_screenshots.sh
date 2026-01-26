#!/bin/bash
# macOS Screenshot Helper for Говорилка
# Run from govorilka directory (root)

set -e

SCREENSHOTS_DIR="fastlane/screenshots"
LOCALES=("ru" "en-US")

# Color definitions
PINK='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${PINK}🖥️  macOS Screenshot Helper for Говорилка${NC}"
echo "=========================================="
echo ""

# Required sizes for App Store
echo -e "${GREEN}Required screenshot sizes:${NC}"
echo "  • Mac: 2880 x 1800 (REQUIRED)"
echo "  • Alternative: 1280 x 800"
echo ""

# Create directories
for locale in "${LOCALES[@]}"; do
    mkdir -p "$SCREENSHOTS_DIR/$locale"
    echo "✓ Directory ready: $SCREENSHOTS_DIR/$locale"
done

echo ""
echo -e "${GREEN}📸 Screenshots to capture (5 total):${NC}"
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ #  │ File                  │ Content                           │"
echo "├─────────────────────────────────────────────────────────────────┤"
echo "│ 1  │ 01_menubar.png        │ Menu bar with popover open        │"
echo "│ 2  │ 02_dictation.png      │ Floating window over text editor  │"
echo "│ 3  │ 03_hotkeys.png        │ Hotkey demonstration              │"
echo "│ 4  │ 04_history.png        │ History view with entries         │"
echo "│ 5  │ 05_privacy.png        │ Privacy & Open Source info        │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

echo -e "${GREEN}Text overlays (RU / EN):${NC}"
echo ""
echo "1. Живёт в меню-баре             │ Lives in Your Menu Bar"
echo "2. Диктуйте в любое приложение   │ Dictate Into Any App"
echo "3. Один хоткей — и вы диктуете   │ One Hotkey to Dictate"
echo "4. История всегда рядом          │ History Always Nearby"
echo "5. Приватность без компромиссов  │ Privacy Without Compromise"
echo ""

# Check current status
echo -e "${YELLOW}Current status:${NC}"
echo ""
for locale in "${LOCALES[@]}"; do
    echo "📁 $locale/:"
    count=0
    for i in {1..5}; do
        case $i in
            1) file="01_menubar.png" ;;
            2) file="02_dictation.png" ;;
            3) file="03_hotkeys.png" ;;
            4) file="04_history.png" ;;
            5) file="05_privacy.png" ;;
        esac
        if [ -f "$SCREENSHOTS_DIR/$locale/$file" ]; then
            echo "   ✅ $file"
            ((count++))
        else
            echo "   ⬜ $file"
        fi
    done
    echo "   Progress: $count/5"
    echo ""
done

# Instructions for capturing
echo -e "${GREEN}📋 How to capture screenshots:${NC}"
echo ""
echo "1. Menu Bar Screenshot:"
echo "   - Click menu bar icon to open popover"
echo "   - Use Cmd+Shift+4, then Space to capture window"
echo "   - Or Cmd+Shift+3 for full screen"
echo ""
echo "2. Floating Window:"
echo "   - Start recording (triggers floating window)"
echo "   - Position over Notes.app or VS Code"
echo "   - Screenshot the composition"
echo ""
echo "3. Hotkeys Screenshot:"
echo "   - Open Settings → Hotkey section"
echo "   - Or create mockup in Figma with keyboard keys"
echo ""
echo "4. History Screenshot:"
echo "   - Add several test recordings first"
echo "   - Open History tab"
echo "   - Screenshot with good sample content"
echo ""
echo "5. Privacy Screenshot:"
echo "   - Create in Figma with icons and text"
echo "   - Minimalist design"
echo ""

# Check if ImageMagick is installed for resizing
if command -v convert &> /dev/null; then
    echo "✓ ImageMagick found - can resize screenshots"
    echo ""
    echo "To resize to Mac size:"
    echo "  convert input.png -resize 2880x1800! output.png"
else
    echo -e "${YELLOW}⚠ ImageMagick not found. Install with: brew install imagemagick${NC}"
fi

echo ""
echo -e "${GREEN}📁 Place final screenshots in:${NC}"
echo "  Russian:  $SCREENSHOTS_DIR/ru/"
echo "  English:  $SCREENSHOTS_DIR/en-US/"
echo ""

# Desktop preparation
echo -e "${GREEN}🖥️  Desktop Preparation:${NC}"
echo ""
echo "  [ ] Clean desktop (remove all icons)"
echo "  [ ] Use light/minimal wallpaper"
echo "  [ ] Open target app (Notes, VS Code, etc.)"
echo "  [ ] Position windows nicely"
echo ""

# Figma checklist
echo -e "${GREEN}🎨 Figma Design Checklist:${NC}"
echo ""
echo "  [ ] Create template 2880×1800"
echo "  [ ] Add screenshot with window chrome"
echo "  [ ] Add text overlay (top, SF Pro Display)"
echo "  [ ] Apply subtle shadow and glow effects"
echo "  [ ] Export PNG (no compression, sRGB)"
echo ""

# Color palette reminder
echo -e "${PINK}🎨 Color Palette:${NC}"
echo ""
echo "  Background:  #FFF5F8 → #FFE4EC"
echo "  Accent:      #FF69B4 → #FFB6C1"
echo "  Text:        #5D4E6D (on light) / #FFFFFF (on dark)"
echo ""
