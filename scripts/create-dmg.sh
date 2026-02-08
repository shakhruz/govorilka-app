#!/bin/bash
# create-dmg.sh — Create branded DMG with Applications symlink and custom layout
# Usage: ./scripts/create-dmg.sh [path-to-app]
#
# If no app path provided, looks for Release build in DerivedData.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Get version
VERSION=$(grep "MARKETING_VERSION:" "$PROJECT_DIR/project.yml" | sed 's/.*"\(.*\)"/\1/')
VOLUME_NAME="Govorilka"
DMG_NAME="Govorilka-${VERSION}.dmg"
DMG_TEMP="${DMG_NAME%.dmg}-temp.dmg"

# Find app
if [ $# -ge 1 ]; then
    APP_PATH="$1"
else
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Govorilka-*/Build/Products/Release -name "Govorilka.app" -type d 2>/dev/null | head -1)
fi

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Govorilka.app не найден. Укажите путь: $0 /path/to/Govorilka.app"
    exit 1
fi

echo "📦 Создаю DMG для: $APP_PATH"
echo "   Версия: $VERSION"

# Cleanup
rm -f "$DMG_NAME" "$DMG_TEMP"

# Create temp directory with app + symlink
STAGING_DIR=$(mktemp -d)
trap "rm -rf '$STAGING_DIR'" EXIT

cp -R "$APP_PATH" "$STAGING_DIR/Govorilka.app"
ln -s /Applications "$STAGING_DIR/Applications"

# Generate background image
BACKGROUND_DIR="$STAGING_DIR/.background"
mkdir -p "$BACKGROUND_DIR"

# Create background using Python (available on all macOS)
python3 - "$BACKGROUND_DIR/dmg-background.png" <<'PYEOF'
import sys
import struct
import zlib

out_path = sys.argv[1]
W, H = 600, 400

# Create pixel data: gradient background with branding colors
rows = []
for y in range(H):
    row = b""
    for x in range(W):
        # Gradient from dark blue-gray to lighter
        t = y / H
        r = int(30 + 20 * t)
        g = int(32 + 22 * t)
        b = int(42 + 28 * t)

        # Subtle center glow
        dx = (x - W/2) / (W/2)
        dy = (y - H/2) / (H/2)
        d = (dx*dx + dy*dy) ** 0.5
        if d < 0.8:
            glow = (1 - d/0.8) * 0.15
            r = min(255, int(r + 80 * glow))
            g = min(255, int(g + 120 * glow))
            b = min(255, int(b + 200 * glow))

        row += struct.pack("BBB", r, g, b)
    rows.append(row)

# Encode as PNG
def make_png(width, height, rows):
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    raw = b""
    for row in rows:
        raw += b"\x00" + row  # filter byte

    return (b"\x89PNG\r\n\x1a\n" +
            chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)) +
            chunk(b"IDAT", zlib.compress(raw, 9)) +
            chunk(b"IEND", b""))

with open(out_path, "wb") as f:
    f.write(make_png(W, H, rows))

print(f"✅ Background: {out_path}")
PYEOF

# Create a R/W DMG
echo "📀 Создаю образ..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING_DIR" \
    -ov -format UDRW -size 200m "$DMG_TEMP"

# Mount it
echo "🔧 Настраиваю внешний вид..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

# Apply Finder layout via AppleScript
osascript <<ASCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        delay 1
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 700, 500}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        set background picture of theViewOptions to file ".background:dmg-background.png"
        -- Position app on the left, Applications on the right
        set position of item "Govorilka.app" of container window to {160, 200}
        set position of item "Applications" of container window to {440, 200}
        close
        open
        delay 1
        close
    end tell
end tell
ASCRIPT

# Set volume icon if we have one
ICON_PATH="$PROJECT_DIR/Govorilka/Resources/Assets.xcassets/AppIcon.appiconset/icon_512_512.png"
if [ -f "$ICON_PATH" ]; then
    # Copy icon as .VolumeIcon.icns (convert PNG to ICNS)
    ICON_TEMP=$(mktemp -d)
    ICONSET="$ICON_TEMP/VolumeIcon.iconset"
    mkdir -p "$ICONSET"
    cp "$ICON_PATH" "$ICONSET/icon_512x512.png"

    ICON_256="$PROJECT_DIR/Govorilka/Resources/Assets.xcassets/AppIcon.appiconset/icon_256_256.png"
    if [ -f "$ICON_256" ]; then
        cp "$ICON_256" "$ICONSET/icon_256x256.png"
    fi

    ICON_128="$PROJECT_DIR/Govorilka/Resources/Assets.xcassets/AppIcon.appiconset/icon_128_128.png"
    if [ -f "$ICON_128" ]; then
        cp "$ICON_128" "$ICONSET/icon_128x128.png"
    fi

    iconutil -c icns -o "$MOUNT_DIR/.VolumeIcon.icns" "$ICONSET" 2>/dev/null || true
    SetFile -a C "$MOUNT_DIR" 2>/dev/null || true
    rm -rf "$ICON_TEMP"
fi

# Hide background directory
SetFile -a V "$MOUNT_DIR/.background" 2>/dev/null || true

# Sync and unmount
sync
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed DMG
echo "🗜️  Сжимаю..."
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"
rm -f "$DMG_TEMP"

echo ""
echo "✅ $DMG_NAME создан!"
echo "   Размер: $(du -h "$DMG_NAME" | cut -f1)"
echo ""
echo "Следующие шаги:"
echo "  codesign --force --timestamp --sign 'Developer ID Application: Shakhruz Ashirov (TZY7G965L4)' $DMG_NAME"
echo "  xcrun notarytool submit $DMG_NAME --keychain-profile 'notarytool' --wait"
echo "  xcrun stapler staple $DMG_NAME"
