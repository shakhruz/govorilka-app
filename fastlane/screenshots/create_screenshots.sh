#!/bin/bash
# Script to help create macOS screenshots for App Store
# Run from govorilka directory

set -e

SCREENSHOTS_DIR="fastlane/screenshots"
LOCALES=("ru" "en-US")

# Required size for Mac App Store
# Mac: 2880 x 1800 (or 1280 x 800 minimum)

echo "🖥  macOS Screenshot Helper for Говорилка"
echo "========================================="
echo ""
echo "Required screenshot size:"
echo "  • Mac: 2880 x 1800 (Retina)"
echo "  • Alternative: 1280 x 800 (minimum)"
echo ""

# Create directories
for locale in "${LOCALES[@]}"; do
    mkdir -p "$SCREENSHOTS_DIR/$locale"
    echo "✓ Created $SCREENSHOTS_DIR/$locale"
done

echo ""
echo "📸 Screenshots to capture:"
echo ""
echo "1. 01_menubar.png   - Menu bar with popover open"
echo "2. 02_floating.png  - Floating window during recording"
echo "3. 03_autopaste.png - Text auto-pasted into editor"
echo "4. 04_history.png   - History tab with entries"
echo "5. 05_hotkeys.png   - Settings with hotkey options"
echo ""

# Instructions for capturing
echo "📋 How to capture screenshots:"
echo ""
echo "Cmd+Shift+3 - Capture entire screen"
echo "Cmd+Shift+4 - Capture selection"
echo "Cmd+Shift+4, Space - Capture window"
echo ""
echo "Tips:"
echo "  • Use clean desktop background"
echo "  • Show app in context (over text editor, etc.)"
echo "  • Hide dock and other apps if possible"
echo ""

# Check if ImageMagick is installed
if command -v convert &> /dev/null; then
    echo "✓ ImageMagick found - can resize screenshots"
    echo ""
    echo "To resize to App Store size:"
    echo "  convert input.png -resize 2880x1800! output.png"
else
    echo "⚠ ImageMagick not found. Install with: brew install imagemagick"
fi

echo ""
echo "📁 Place screenshots in:"
echo "  Russian:  $SCREENSHOTS_DIR/ru/"
echo "  English:  $SCREENSHOTS_DIR/en-US/"
echo ""
echo "Naming: {order}_{screen_name}.png"
echo "Example: 01_menubar.png, 02_floating.png"
