#!/usr/bin/env python3
"""Generate app icon for Govorilka app."""

from PIL import Image, ImageDraw, ImageFilter
import os
import math

def create_gradient(size, color1, color2, direction='vertical'):
    """Create a gradient image."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    for y in range(size):
        for x in range(size):
            if direction == 'vertical':
                ratio = y / size
            elif direction == 'horizontal':
                ratio = x / size
            else:  # radial
                cx, cy = size / 2, size / 2
                dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
                max_dist = math.sqrt(2) * size / 2
                ratio = min(1.0, dist / max_dist)

            r = int(color1[0] + (color2[0] - color1[0]) * ratio)
            g = int(color1[1] + (color2[1] - color1[1]) * ratio)
            b = int(color1[2] + (color2[2] - color1[2]) * ratio)
            a = int(color1[3] + (color2[3] - color1[3]) * ratio) if len(color1) > 3 else 255

            img.putpixel((x, y), (r, g, b, a))

    return img


def draw_rounded_rect(draw, bbox, radius, fill=None, outline=None, width=1):
    """Draw a rounded rectangle."""
    x1, y1, x2, y2 = bbox

    # Draw rectangles
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)

    # Draw corners
    draw.ellipse([x1, y1, x1 + radius * 2, y1 + radius * 2], fill=fill)
    draw.ellipse([x2 - radius * 2, y1, x2, y1 + radius * 2], fill=fill)
    draw.ellipse([x1, y2 - radius * 2, x1 + radius * 2, y2], fill=fill)
    draw.ellipse([x2 - radius * 2, y2 - radius * 2, x2, y2], fill=fill)


def create_app_icon(size):
    """Create the app icon at specified size."""
    # Create base image with gradient background
    # Purple/blue gradient - modern voice app aesthetic
    color_top = (88, 86, 214, 255)      # Purple
    color_bottom = (45, 135, 255, 255)  # Blue

    img = create_gradient(size, color_top, color_bottom, 'vertical')
    draw = ImageDraw.Draw(img)

    # Scale factor
    s = size / 512

    # Draw rounded rectangle background (iOS/macOS style)
    corner_radius = int(100 * s)
    margin = int(10 * s)

    # Add subtle inner shadow/glow
    shadow_color = (0, 0, 0, 30)
    for i in range(3):
        offset = int((3 - i) * s)
        draw.rounded_rectangle(
            [margin + offset, margin + offset, size - margin - offset, size - margin - offset],
            radius=corner_radius - offset,
            outline=shadow_color,
            width=int(2 * s)
        )

    # Microphone dimensions
    mic_width = int(140 * s)
    mic_height = int(200 * s)
    mic_x = (size - mic_width) // 2
    mic_y = int(100 * s)
    mic_radius = mic_width // 2

    # Microphone body color (white with slight transparency)
    mic_color = (255, 255, 255, 255)
    mic_shadow = (0, 0, 0, 40)

    # Draw microphone shadow
    shadow_offset = int(8 * s)
    draw.rounded_rectangle(
        [mic_x + shadow_offset, mic_y + shadow_offset,
         mic_x + mic_width + shadow_offset, mic_y + mic_height + shadow_offset],
        radius=mic_radius,
        fill=mic_shadow
    )

    # Draw microphone body (rounded rectangle)
    draw.rounded_rectangle(
        [mic_x, mic_y, mic_x + mic_width, mic_y + mic_height],
        radius=mic_radius,
        fill=mic_color
    )

    # Microphone grille lines
    grille_color = (200, 200, 220, 255)
    grille_start_y = mic_y + int(40 * s)
    grille_end_y = mic_y + mic_height - int(40 * s)
    grille_spacing = max(4, int(20 * s))
    grille_margin = max(3, int(25 * s))
    line_width = max(1, int(2 * s))

    for y in range(int(grille_start_y), int(grille_end_y), grille_spacing):
        draw.line(
            [(mic_x + grille_margin, y), (mic_x + mic_width - grille_margin, y)],
            fill=grille_color,
            width=line_width
        )

    # Stand arc
    arc_width = int(220 * s)
    arc_height = int(100 * s)
    arc_x = (size - arc_width) // 2
    arc_y = mic_y + mic_height - int(30 * s)
    arc_thickness = int(12 * s)

    # Draw arc shadow
    draw.arc(
        [arc_x + shadow_offset, arc_y + shadow_offset,
         arc_x + arc_width + shadow_offset, arc_y + arc_height + shadow_offset],
        start=0, end=180,
        fill=mic_shadow,
        width=arc_thickness
    )

    # Draw arc
    draw.arc(
        [arc_x, arc_y, arc_x + arc_width, arc_y + arc_height],
        start=0, end=180,
        fill=mic_color,
        width=arc_thickness
    )

    # Vertical stand
    stand_width = int(12 * s)
    stand_x = (size - stand_width) // 2
    stand_top = arc_y + arc_height // 2
    stand_bottom = int(380 * s)

    draw.rectangle(
        [stand_x + shadow_offset, stand_top + shadow_offset,
         stand_x + stand_width + shadow_offset, stand_bottom + shadow_offset],
        fill=mic_shadow
    )
    draw.rectangle(
        [stand_x, stand_top, stand_x + stand_width, stand_bottom],
        fill=mic_color
    )

    # Base
    base_width = int(120 * s)
    base_height = int(12 * s)
    base_x = (size - base_width) // 2
    base_y = stand_bottom

    draw.rounded_rectangle(
        [base_x + shadow_offset, base_y + shadow_offset,
         base_x + base_width + shadow_offset, base_y + base_height + shadow_offset],
        radius=int(6 * s),
        fill=mic_shadow
    )
    draw.rounded_rectangle(
        [base_x, base_y, base_x + base_width, base_y + base_height],
        radius=int(6 * s),
        fill=mic_color
    )

    # Sound waves (decorative)
    wave_color = (255, 255, 255, 100)
    wave_x = mic_x + mic_width + int(30 * s)
    wave_center_y = mic_y + mic_height // 2

    for i, radius in enumerate([30, 50, 70]):
        r = int(radius * s)
        alpha = 100 - i * 30
        wave_col = (255, 255, 255, alpha)
        draw.arc(
            [wave_x, wave_center_y - r, wave_x + r * 2, wave_center_y + r],
            start=-60, end=60,
            fill=wave_col,
            width=int(4 * s)
        )

    # Left side waves (mirrored)
    wave_x_left = mic_x - int(30 * s)
    for i, radius in enumerate([30, 50, 70]):
        r = int(radius * s)
        alpha = 100 - i * 30
        wave_col = (255, 255, 255, alpha)
        draw.arc(
            [wave_x_left - r * 2, wave_center_y - r, wave_x_left, wave_center_y + r],
            start=120, end=240,
            fill=wave_col,
            width=int(4 * s)
        )

    return img


def generate_all_icons(output_dir):
    """Generate all required icon sizes."""
    # macOS icon sizes (for AppIcon.appiconset)
    sizes = [
        (16, '16x16', '1x'),
        (32, '16x16', '2x'),
        (32, '32x32', '1x'),
        (64, '32x32', '2x'),
        (128, '128x128', '1x'),
        (256, '128x128', '2x'),
        (256, '256x256', '1x'),
        (512, '256x256', '2x'),
        (512, '512x512', '1x'),
        (1024, '512x512', '2x'),
    ]

    os.makedirs(output_dir, exist_ok=True)

    # Generate each size
    generated_files = []
    for pixel_size, size_name, scale in sizes:
        icon = create_app_icon(pixel_size)

        if scale == '1x':
            filename = f'icon_{size_name.replace("x", "_")}.png'
        else:
            filename = f'icon_{size_name.replace("x", "_")}@2x.png'

        filepath = os.path.join(output_dir, filename)
        icon.save(filepath, 'PNG')
        generated_files.append((filename, size_name, scale))
        print(f'Created: {filepath} ({pixel_size}x{pixel_size})')

    # Generate Contents.json
    generate_contents_json(output_dir, generated_files)

    # Also generate a large preview
    preview = create_app_icon(512)
    preview_path = os.path.join(output_dir, '..', 'app-icon-preview.png')
    preview.save(preview_path, 'PNG')
    print(f'\nPreview saved: {preview_path}')


def generate_contents_json(output_dir, files):
    """Generate Contents.json for the asset catalog."""
    images = []

    for filename, size, scale in files:
        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": scale,
            "size": size
        })

    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    import json
    contents_path = os.path.join(output_dir, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f'Created: {contents_path}')


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(
        script_dir, '..', 'Govorilka', 'Resources',
        'Assets.xcassets', 'AppIcon.appiconset'
    )

    generate_all_icons(output_dir)
    print('\nDone! App icon generated.')
