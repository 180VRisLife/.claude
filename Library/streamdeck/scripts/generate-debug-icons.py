#!/usr/bin/env python3
"""
Generate debug icons for Stream Deck plugin actions.

This script takes plugin action icons and generates debug versions
with a red diagonal slash and "DEV" text overlay.

Usage:
    python3 generate-debug-icons.py <plugin_directory>

Example:
    python3 generate-debug-icons.py ./com.example.myplugin.sdPlugin
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


def add_debug_overlay(img: Image.Image, size: str) -> Image.Image:
    """Add diagonal red slash and DEV badge to icon."""
    width, height = img.size
    draw = ImageDraw.Draw(img, 'RGBA')

    # Add diagonal red slash
    slash_color = (255, 59, 48, 200)  # Red with alpha
    slash_width = max(3, width // 25)

    # Draw diagonal line
    for i in range(slash_width):
        draw.line(
            [(i, 0), (width, height - slash_width + i)],
            fill=slash_color,
            width=slash_width
        )

    # Add DEV badge in corner
    badge_text = "DEV"
    font_size = max(10, width // 8)

    try:
        # Try to load a system font
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

    # Get text bounding box
    bbox = draw.textbbox((0, 0), badge_text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Position in bottom-left
    text_x = width // 20
    text_y = height - text_height - (height // 15)

    # Draw text outline
    outline_color = (0, 0, 0, 255)
    outline_width = max(1, width // 100)

    for adj_x in range(-outline_width, outline_width + 1):
        for adj_y in range(-outline_width, outline_width + 1):
            draw.text((text_x + adj_x, text_y + adj_y), badge_text, font=font, fill=outline_color)

    # Draw main text
    draw.text((text_x, text_y), badge_text, font=font, fill=(255, 255, 255, 255))

    return img


def process_plugin_icons(plugin_dir: Path) -> bool:
    """Process all action icons in the plugin directory."""
    imgs_dir = plugin_dir / "imgs"

    if not imgs_dir.exists():
        print(f"  ℹ  No imgs/ directory found, skipping icon generation")
        return False

    # Find all PNG files in imgs directory (recursively)
    png_files = list(imgs_dir.glob("**/*.png"))

    if not png_files:
        print(f"  ℹ  No PNG icons found in imgs/ directory")
        return False

    generated_count = 0

    for png_file in png_files:
        # Skip if already a debug icon
        if "-dev" in png_file.stem.lower() or "-debug" in png_file.stem.lower():
            continue

        # Generate debug variant filename
        debug_filename = f"{png_file.stem}-dev{png_file.suffix}"
        debug_path = png_file.parent / debug_filename

        if debug_path.exists():
            print(f"  ℹ  {debug_path.relative_to(plugin_dir)} already exists, skipping")
            continue

        print(f"  ✓ Generating {debug_path.relative_to(plugin_dir)}")

        try:
            # Load original image
            img = Image.open(png_file).convert('RGBA')

            # Determine size category for appropriate overlay
            width = img.size[0]
            if width <= 72:
                size = "small"
            elif width <= 144:
                size = "medium"
            else:
                size = "large"

            # Add debug overlay
            debug_img = add_debug_overlay(img, size)

            # Save debug variant
            debug_img.save(str(debug_path), format='PNG')
            generated_count += 1

        except Exception as e:
            print(f"  ! Error processing {png_file.name}: {e}")

    return generated_count > 0


def main():
    parser = argparse.ArgumentParser(
        description="Generate debug icons for Stream Deck plugin actions"
    )
    parser.add_argument(
        "plugin_dir",
        type=str,
        help="Path to .sdPlugin directory"
    )

    args = parser.parse_args()
    plugin_dir = Path(args.plugin_dir)

    if not plugin_dir.exists():
        print(f"❌ Error: Plugin directory not found: {plugin_dir}")
        sys.exit(1)

    if not plugin_dir.is_dir():
        print(f"❌ Error: Not a directory: {plugin_dir}")
        sys.exit(1)

    print(f"\n🎨 Generating debug icons for Stream Deck plugin...")
    print(f"   Plugin: {plugin_dir.name}")

    success = process_plugin_icons(plugin_dir)

    if success:
        print(f"\n✅ Debug icons generated successfully!")
        print(f"   You can re-run this script anytime to update debug icons.")
        print(f"   Remember to update manifest references to use -dev icons in development.")
    else:
        print(f"\n✅ No icons to generate (all debug icons already exist)")


if __name__ == "__main__":
    main()
