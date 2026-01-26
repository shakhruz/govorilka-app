#!/bin/bash
# Script to help create iOS screenshots for App Store
# Run from govorilka-mobile directory

set -e

SCREENSHOTS_DIR="fastlane/screenshots"
LOCALES=("ru" "en-US")

# Required sizes for App Store
# iPhone 6.7" (iPhone 15 Pro Max): 1290 x 2796
# iPhone 6.5" (iPhone 11 Pro Max): 1284 x 2778

echo "📱 iOS Screenshot Helper for Говорилка"
echo "======================================="
echo ""
echo "Required screenshot sizes:"
echo "  • iPhone 6.7\" (15 Pro Max): 1290 x 2796"
echo "  • iPhone 6.5\" (11 Pro Max): 1284 x 2778"
echo ""

# Create directories
for locale in "${LOCALES[@]}"; do
    mkdir -p "$SCREENSHOTS_DIR/$locale"
    echo "✓ Created $SCREENSHOTS_DIR/$locale"
done

echo ""
echo "📸 Screenshots to capture:"
echo ""
echo "1. 01_recording.png    - Main screen with record button"
echo "2. 02_transcribing.png - Active recording with waveform"
echo "3. 03_history.png      - History list with entries"
echo "4. 04_settings.png     - Settings screen"
echo "5. 05_pro_mode.png     - Recording with photo attached"
echo "6. 06_cleanup.png      - Text cleanup feature"
echo ""

# Instructions for capturing
echo "📋 How to capture screenshots:"
echo ""
echo "Option 1: Simulator (Recommended)"
echo "  1. Run app in iOS Simulator"
echo "  2. Use Cmd+S to save screenshot"
echo "  3. Rename and move to appropriate folder"
echo ""
echo "Option 2: Physical device"
echo "  1. Press Side + Volume Up buttons"
echo "  2. Transfer to Mac via AirDrop"
echo "  3. Rename and move to appropriate folder"
echo ""
echo "Option 3: Expo screenshot"
echo "  npx expo start"
echo "  Press 's' in terminal to take screenshot"
echo ""

# Check if ImageMagick is installed for resizing
if command -v convert &> /dev/null; then
    echo "✓ ImageMagick found - can resize screenshots"
    echo ""
    echo "To resize a screenshot to 6.7\" size:"
    echo "  convert input.png -resize 1290x2796! output.png"
else
    echo "⚠ ImageMagick not found. Install with: brew install imagemagick"
fi

echo ""
echo "📁 Place screenshots in:"
echo "  Russian:  $SCREENSHOTS_DIR/ru/"
echo "  English:  $SCREENSHOTS_DIR/en-US/"
echo ""
echo "Naming convention: {order}_{screen_name}.png"
echo "Example: 01_recording.png, 02_transcribing.png"
