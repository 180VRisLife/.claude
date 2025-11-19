#!/usr/bin/env python3
"""
Generate debug favicon with visual indicator.

This script takes a favicon and generates a debug version
with a red dot or "DEV" badge overlay.

Usage:
    python3 generate-debug-favicon.py <public_directory>

Example:
    python3 generate-debug-favicon.py ./public
"""

import sys
import argparse
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("❌ Error: Pillow is not installed")
    print("   Install with: pip install Pillow")
    sys.exit(1)


def create_blank_favicon(size: int = 32) -> Image.Image:
    """Create a blank favicon with a subtle color."""
    img = Image.new('RGBA', (size, size), color=(45, 45, 48, 255))
    return img


def add_debug_indicator(img: Image.Image, style: str = 'dot') -> Image.Image:
    """Add debug indicator to favicon."""
    width, height = img.size
    draw = ImageDraw.Draw(img, 'RGBA')

    if style == 'dot':
        # Add red dot in top-right corner
        dot_size = max(8, width // 4)
        dot_x = width - dot_size - 2
        dot_y = 2

        # Draw filled circle
        draw.ellipse(
            [dot_x, dot_y, dot_x + dot_size, dot_y + dot_size],
            fill=(255, 59, 48, 255),  # Red
            outline=(255, 255, 255, 200),
            width=1
        )

    elif style == 'badge':
        # Add "DEV" badge
        badge_text = "D"  # Short for small favicons
        font_size = max(10, width // 3)

        try:
            font_paths = [
                "/System/Library/Fonts/Helvetica.ttc",  # macOS
                "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",  # Linux
                "C:\\Windows\\Fonts\\arial.ttf",  # Windows
            ]

            font = None
            for font_path in font_paths:
                if Path(font_path).exists():
                    font = ImageFont.truetype(font_path, font_size)
                    break

            if font is None:
                font = ImageFont.load_default()
        except Exception:
            font = ImageFont.load_default()

        # Add semi-transparent red background
        badge_bg = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        bg_draw = ImageDraw.Draw(badge_bg)

        bg_draw.rectangle(
            [0, height - font_size - 4, width, height],
            fill=(255, 59, 48, 220)
        )

        # Composite background
        img = Image.alpha_composite(img.convert('RGBA'), badge_bg)
        draw = ImageDraw.Draw(img)

        # Get text bounding box
        bbox = draw.textbbox((0, 0), badge_text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]

        # Center text
        text_x = (width - text_width) // 2
        text_y = height - text_height - 2

        # Draw text
        draw.text((text_x, text_y), badge_text, font=font, fill=(255, 255, 255, 255))

    elif style == 'slash':
        # Add diagonal red slash
        slash_color = (255, 59, 48, 200)
        slash_width = max(2, width // 16)

        for i in range(slash_width):
            draw.line(
                [(i, 0), (width, height - slash_width + i)],
                fill=slash_color,
                width=slash_width
            )

    return img


def process_favicon(public_dir: Path, style: str = 'dot') -> bool:
    """Process favicon files in public directory."""
    # Common favicon file names
    favicon_names = ['favicon.ico', 'favicon.png', 'icon.png', 'apple-touch-icon.png']

    found_favicon = None
    for name in favicon_names:
        favicon_path = public_dir / name
        if favicon_path.exists():
            found_favicon = favicon_path
            break

    if not found_favicon:
        print(f"  ℹ  No favicon found, creating blank favicon.png")
        # Create blank favicon
        blank = create_blank_favicon(32)
        favicon_path = public_dir / "favicon.png"
        blank.save(str(favicon_path), format='PNG')
        found_favicon = favicon_path

    print(f"  ✓ Found favicon: {found_favicon.name}")

    # Generate debug variant
    debug_name = found_favicon.stem + '-dev' + found_favicon.suffix
    debug_path = public_dir / debug_name

    if debug_path.exists():
        print(f"  ℹ  {debug_name} already exists, skipping")
        return False

    print(f"  ✓ Generating {debug_name} with {style} indicator")

    try:
        # Load original
        if found_favicon.suffix == '.ico':
            # ICO files can have multiple sizes, process largest
            img = Image.open(found_favicon)
            img = img.convert('RGBA')
        else:
            img = Image.open(found_favicon).convert('RGBA')

        # Add debug indicator
        debug_img = add_debug_indicator(img, style)

        # Save debug variant
        if debug_path.suffix == '.ico':
            # Save as PNG instead for better transparency
            debug_path = public_dir / (debug_path.stem + '.png')

        debug_img.save(str(debug_path), format='PNG')

        return True

    except Exception as e:
        print(f"  ! Error processing favicon: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Generate debug favicon with visual indicator"
    )
    parser.add_argument(
        "public_dir",
        type=str,
        help="Path to public directory (usually ./public or ./app)"
    )
    parser.add_argument(
        "--style",
        type=str,
        choices=['dot', 'badge', 'slash'],
        default='dot',
        help="Style of debug indicator (default: dot)"
    )

    args = parser.parse_args()
    public_dir = Path(args.public_dir)

    if not public_dir.exists():
        print(f"❌ Error: Public directory not found: {public_dir}")
        sys.exit(1)

    if not public_dir.is_dir():
        print(f"❌ Error: Not a directory: {public_dir}")
        sys.exit(1)

    print(f"\n🎨 Generating debug favicon...")
    print(f"   Directory: {public_dir}")
    print(f"   Style: {args.style}")

    success = process_favicon(public_dir, args.style)

    if success:
        print(f"\n✅ Debug favicon generated successfully!")
        print(f"   Update your app/layout.tsx to use conditional favicon:")
        print(f"   <link rel=\"icon\" href=\"/favicon{{process.env.NODE_ENV === 'development' ? '-dev' : ''}}.png\" />")
    else:
        print(f"\n✅ Debug favicon already exists (no changes made)")


if __name__ == "__main__":
    main()
