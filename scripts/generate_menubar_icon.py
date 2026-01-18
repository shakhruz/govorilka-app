#!/usr/bin/env python3
"""Generate menu bar icons for Govorilka app."""

from PIL import Image, ImageDraw
import os

def draw_microphone(draw, size, color='black'):
    """Draw a microphone icon."""
    # Scale factor based on size
    scale = size / 22

    # Microphone body (rounded rectangle / ellipse)
    mic_left = int(7 * scale)
    mic_top = int(3 * scale)
    mic_right = int(15 * scale)
    mic_bottom = int(14 * scale)

    # Draw mic body as ellipse (rounded top/bottom)
    draw.ellipse([mic_left, mic_top, mic_right, mic_bottom], fill=color)

    # Stand arc
    arc_left = int(5 * scale)
    arc_top = int(8 * scale)
    arc_right = int(17 * scale)
    arc_bottom = int(20 * scale)
    line_width = max(1, int(1.5 * scale))

    draw.arc([arc_left, arc_top, arc_right, arc_bottom], start=0, end=180, fill=color, width=line_width)

    # Vertical line
    center_x = size // 2
    line_top = int(17 * scale)
    line_bottom = int(19 * scale)
    draw.line([(center_x, line_top), (center_x, line_bottom)], fill=color, width=line_width)

    # Base line
    base_left = int(8 * scale)
    base_right = int(14 * scale)
    base_y = int(19 * scale)
    draw.line([(base_left, base_y), (base_right, base_y)], fill=color, width=line_width)


def generate_icons(output_dir):
    """Generate menu bar icons at different sizes."""
    sizes = [
        (16, ''),      # 1x
        (32, '@2x'),   # 2x retina
        (48, '@3x'),   # 3x (for future)
    ]

    os.makedirs(output_dir, exist_ok=True)

    for size, suffix in sizes:
        # Create transparent image
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Draw microphone in black (will be tinted by macOS as template)
        draw_microphone(draw, size, color='black')

        # Save
        filename = f'menubar{suffix}.png'
        filepath = os.path.join(output_dir, filename)
        img.save(filepath, 'PNG')
        print(f'Created: {filepath}')


def generate_recording_icons(output_dir):
    """Generate recording state icons (filled microphone)."""
    sizes = [
        (16, ''),
        (32, '@2x'),
        (48, '@3x'),
    ]

    for size, suffix in sizes:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Draw filled microphone
        draw_microphone(draw, size, color='black')

        # Add recording indicator (small dot)
        scale = size / 22
        dot_size = max(3, int(4 * scale))
        dot_x = int(16 * scale)
        dot_y = int(4 * scale)
        draw.ellipse([dot_x, dot_y, dot_x + dot_size, dot_y + dot_size], fill='black')

        filename = f'menubar-recording{suffix}.png'
        filepath = os.path.join(output_dir, filename)
        img.save(filepath, 'PNG')
        print(f'Created: {filepath}')


if __name__ == '__main__':
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, '..', 'Govorilka', 'Resources', 'Assets.xcassets', 'MenuBarIcon.imageset')

    generate_icons(output_dir)
    generate_recording_icons(output_dir)

    print('\nDone! Update Contents.json to include the new images.')
