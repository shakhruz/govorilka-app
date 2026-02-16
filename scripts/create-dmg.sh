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

# Create premium background using Python (available on all macOS)
python3 - "$BACKGROUND_DIR/dmg-background.png" <<'PYEOF'
import sys, struct, zlib, math

out_path = sys.argv[1]
W, H = 600, 400

# App pink palette
TOP = (255, 245, 248)       # #FFF5F8
BOT = (255, 228, 236)       # #FFE4EC
GLOW = (255, 182, 193)      # #FFB6C1 lightPink
ARROW_CLR = (255, 255, 255) # white arrow
ARROW_SHADOW = (255, 105, 180) # #FF69B4 pinkColor

def lerp(a, b, t):
    return a + (b - a) * t

def clamp(v):
    return max(0, min(255, int(v)))

# Pre-compute pixels as RGBA for alpha blending
pixels = [[(0,0,0)] * W for _ in range(H)]

# 1. Pink gradient background
for y in range(H):
    t = y / H
    for x in range(W):
        r = lerp(TOP[0], BOT[0], t)
        g = lerp(TOP[1], BOT[1], t)
        b = lerp(TOP[2], BOT[2], t)
        pixels[y][x] = (r, g, b)

# 2. Soft center glow
cx, cy = W / 2, H / 2 - 20
for y in range(H):
    for x in range(W):
        dx = (x - cx) / (W * 0.4)
        dy = (y - cy) / (H * 0.4)
        d = math.sqrt(dx*dx + dy*dy)
        if d < 1.0:
            strength = (1 - d) ** 2 * 0.25
            pr, pg, pb = pixels[y][x]
            r = lerp(pr, GLOW[0], strength)
            g = lerp(pg, GLOW[1], strength)
            b = lerp(pb, GLOW[2], strength)
            pixels[y][x] = (r, g, b)

# 3. Draw arrow from app (x=160) to Applications (x=440) at y~200
# Arrow body: thick rounded line from x=220 to x=390, y=195..205
ARROW_Y = 200
BODY_LEFT = 225
BODY_RIGHT = 390
BODY_HALF = 5
HEAD_TIP = 415
HEAD_HALF = 22

def draw_circle_blend(cx, cy, radius, color, alpha):
    for y in range(max(0, int(cy-radius-2)), min(H, int(cy+radius+2))):
        for x in range(max(0, int(cx-radius-2)), min(W, int(cx+radius+2))):
            d = math.sqrt((x-cx)**2 + (y-cy)**2)
            if d <= radius:
                edge = max(0, 1 - max(0, d - radius + 1.5) / 1.5)
                a = alpha * edge
                pr, pg, pb = pixels[y][x]
                pixels[y][x] = (lerp(pr, color[0], a), lerp(pg, color[1], a), lerp(pb, color[2], a))

# Shadow offset
for offset_y in [2]:
    # Arrow body shadow
    for y in range(ARROW_Y - BODY_HALF + offset_y, ARROW_Y + BODY_HALF + offset_y + 1):
        if 0 <= y < H:
            for x in range(BODY_LEFT, BODY_RIGHT + 1):
                dy = abs(y - (ARROW_Y + offset_y))
                edge = max(0, 1 - max(0, dy - BODY_HALF + 1.5) / 1.5)
                a = 0.12 * edge
                pr, pg, pb = pixels[y][x]
                pixels[y][x] = (lerp(pr, ARROW_SHADOW[0], a), lerp(pg, ARROW_SHADOW[1], a), lerp(pb, ARROW_SHADOW[2], a))

    # Arrow head shadow
    for y in range(ARROW_Y - HEAD_HALF + offset_y - 2, ARROW_Y + HEAD_HALF + offset_y + 3):
        if 0 <= y < H:
            progress = 0
            for x in range(BODY_RIGHT - 5, HEAD_TIP + 3):
                if x < BODY_RIGHT:
                    half = HEAD_HALF
                else:
                    t = (x - BODY_RIGHT) / max(1, HEAD_TIP - BODY_RIGHT)
                    half = HEAD_HALF * (1 - t)
                dy = abs(y - (ARROW_Y + offset_y))
                if dy <= half + 1.5:
                    edge = max(0, 1 - max(0, dy - half + 1) / 1.5)
                    a = 0.12 * edge
                    pr, pg, pb = pixels[y][x]
                    pixels[y][x] = (lerp(pr, ARROW_SHADOW[0], a), lerp(pg, ARROW_SHADOW[1], a), lerp(pb, ARROW_SHADOW[2], a))

# Arrow body (white)
for y in range(ARROW_Y - BODY_HALF, ARROW_Y + BODY_HALF + 1):
    if 0 <= y < H:
        for x in range(BODY_LEFT, BODY_RIGHT + 1):
            dy = abs(y - ARROW_Y)
            edge = max(0, 1 - max(0, dy - BODY_HALF + 1.5) / 1.5)
            a = 0.85 * edge
            pr, pg, pb = pixels[y][x]
            pixels[y][x] = (lerp(pr, ARROW_CLR[0], a), lerp(pg, ARROW_CLR[1], a), lerp(pb, ARROW_CLR[2], a))

# Arrow head (triangle pointing right)
for y in range(ARROW_Y - HEAD_HALF - 2, ARROW_Y + HEAD_HALF + 3):
    if 0 <= y < H:
        for x in range(BODY_RIGHT - 5, HEAD_TIP + 2):
            if x < BODY_RIGHT:
                half = HEAD_HALF
            else:
                t = (x - BODY_RIGHT) / max(1, HEAD_TIP - BODY_RIGHT)
                half = HEAD_HALF * (1 - t)
            dy = abs(y - ARROW_Y)
            if dy <= half + 1.5:
                edge = max(0, 1 - max(0, dy - half + 1) / 1.5)
                a = 0.85 * edge
                pr, pg, pb = pixels[y][x]
                pixels[y][x] = (lerp(pr, ARROW_CLR[0], a), lerp(pg, ARROW_CLR[1], a), lerp(pb, ARROW_CLR[2], a))

# 4. Small decorative dots (subtle)
for dot_x, dot_y, dot_r in [(100, 80, 20), (500, 100, 15), (80, 320, 12), (520, 310, 18)]:
    for y in range(max(0, dot_y - dot_r - 2), min(H, dot_y + dot_r + 2)):
        for x in range(max(0, dot_x - dot_r - 2), min(W, dot_x + dot_r + 2)):
            d = math.sqrt((x - dot_x)**2 + (y - dot_y)**2)
            if d < dot_r:
                strength = (1 - d / dot_r) ** 2 * 0.08
                pr, pg, pb = pixels[y][x]
                pixels[y][x] = (lerp(pr, 255, strength), lerp(pg, 182, strength), lerp(pb, 193, strength))

# Encode rows
rows = []
for y in range(H):
    row = b""
    for x in range(W):
        r, g, b = pixels[y][x]
        row += struct.pack("BBB", clamp(r), clamp(g), clamp(b))
    rows.append(row)

# Encode as PNG
def make_png(width, height, rows):
    def chunk(ctype, data):
        c = ctype + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)
    raw = b""
    for row in rows:
        raw += b"\x00" + row
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
echo "   Ожидаю появления диска в Finder..."
sleep 5

osascript <<ASCRIPT
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        delay 3
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
        delay 2
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
