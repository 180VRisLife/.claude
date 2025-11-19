#!/usr/bin/env python3
"""
Generate debug app icons with diagonal slash overlay.

This script takes an input icon (or creates a blank one if missing) and generates
a debug version with a red diagonal slash and "DEBUG" text overlay.

Usage:
    python3 generate-debug-icon.py <assets_path> [--icon-name AppIcon]

Example:
    python3 generate-debug-icon.py ./MyApp/Assets.xcassets
    python3 generate-debug-icon.py ./MyApp/Assets.xcassets --icon-name AppIcon
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


def create_blank_icon(size: int = 1024) -> Image.Image:
    """Create a blank icon with a subtle gradient."""
    img = Image.new('RGB', (size, size), color=(45, 45, 48))
    draw = ImageDraw.Draw(img)

    # Add subtle gradient effect
    for y in range(size):
        alpha = int(255 * (y / size) * 0.1)
        color = (45 + alpha // 4, 45 + alpha // 4, 48 + alpha // 4)
        draw.line([(0, y), (size, y)], fill=color)

    return img


def add_debug_overlay(img: Image.Image) -> Image.Image:
    """Add diagonal red slash and DEBUG text to icon."""
    width, height = img.size
    draw = ImageDraw.Draw(img, 'RGBA')

    # Add diagonal red slash (slightly transparent)
    slash_color = (255, 59, 48, 200)  # iOS red with alpha
    slash_width = max(10, width // 50)

    # Draw thick diagonal line
    for i in range(slash_width):
        draw.line(
            [(i, 0), (width, height - slash_width + i)],
            fill=slash_color,
            width=slash_width
        )

    # Add DEBUG text
    text = "DEBUG"

    # Try to load a system font
    try:
        # Try common system fonts
        font_size = max(48, width // 12)
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",  # macOS
            "/System/Library/Fonts/SFCompact.ttf",  # macOS SF
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
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Position text in bottom-left area (avoiding slash)
    text_x = width // 20
    text_y = height - text_height - (height // 15)

    # Draw text with outline for better visibility
    outline_color = (0, 0, 0, 255)
    outline_width = max(2, width // 200)

    # Draw outline
    for adj_x in range(-outline_width, outline_width + 1):
        for adj_y in range(-outline_width, outline_width + 1):
            draw.text((text_x + adj_x, text_y + adj_y), text, font=font, fill=outline_color)

    # Draw main text
    draw.text((text_x, text_y), text, font=font, fill=(255, 255, 255, 255))

    return img


def process_solidimagestack(assets_path: Path, icon_name: str) -> bool:
    """Process visionOS solid image stack icons."""
    release_stack = assets_path / f"{icon_name}.solidimagestack"
    debug_stack = assets_path / f"{icon_name}-Debug.solidimagestack"

    if not release_stack.exists():
        print(f"  ℹ  Creating blank {icon_name}.solidimagestack")
        release_stack.mkdir(parents=True)

        # Create Contents.json for solid image stack
        contents_json = {
            "info": {"author": "xcode", "version": 1},
            "layers": [
                {"filename": "Front.solidimagestacklayer"},
                {"filename": "Middle.solidimagestacklayer"},
                {"filename": "Back.solidimagestacklayer"}
            ]
        }

        import json
        (release_stack / "Contents.json").write_text(json.dumps(contents_json, indent=2))

        # Create layer directories with blank icons
        for layer in ["Front", "Middle", "Back"]:
            layer_dir = release_stack / f"{layer}.solidimagestacklayer"
            layer_dir.mkdir()

            layer_contents = {
                "info": {"author": "xcode", "version": 1}
            }
            (layer_dir / "Contents.json").write_text(json.dumps(layer_contents, indent=2))

            # Create blank image for this layer
            blank_img = create_blank_icon(1024)
            (layer_dir / "Content.png").write_bytes(blank_img.tobytes('png'))
            blank_img.save(str(layer_dir / "Content.png"), format='PNG')

    # Create debug version
    if debug_stack.exists():
        print(f"  ℹ  {icon_name}-Debug.solidimagestack already exists, skipping")
        return False

    print(f"  ✓ Creating {icon_name}-Debug.solidimagestack with debug overlay")
    debug_stack.mkdir(parents=True)

    # Copy structure from release
    import shutil
    import json

    # Copy Contents.json
    shutil.copy2(release_stack / "Contents.json", debug_stack / "Contents.json")

    # Process each layer
    for layer in ["Front", "Middle", "Back"]:
        src_layer = release_stack / f"{layer}.solidimagestacklayer"
        dst_layer = debug_stack / f"{layer}.solidimagestacklayer"

        if src_layer.exists():
            dst_layer.mkdir()
            shutil.copy2(src_layer / "Contents.json", dst_layer / "Contents.json")

            # Process image if exists
            src_image = src_layer / "Content.png"
            dst_image = dst_layer / "Content.png"

            if src_image.exists():
                img = Image.open(src_image).convert('RGBA')
            else:
                img = create_blank_icon(1024)

            # Add debug overlay to front layer only
            if layer == "Front":
                img = add_debug_overlay(img)

            img.save(str(dst_image), format='PNG')

    return True


def process_appiconset(assets_path: Path, icon_name: str) -> bool:
    """Process iOS/macOS .appiconset icons."""
    release_iconset = assets_path / f"{icon_name}.appiconset"
    debug_iconset = assets_path / f"{icon_name}-Debug.appiconset"

    if not release_iconset.exists():
        print(f"  ℹ  Creating blank {icon_name}.appiconset")
        release_iconset.mkdir(parents=True)

        # Create basic Contents.json
        import json
        contents = {
            "images": [
                {
                    "filename": "Icon-1024.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                }
            ],
            "info": {"author": "xcode", "version": 1}
        }
        (release_iconset / "Contents.json").write_text(json.dumps(contents, indent=2))

        # Create blank 1024x1024 icon
        blank_img = create_blank_icon(1024)
        blank_img.save(str(release_iconset / "Icon-1024.png"), format='PNG')

    # Create debug version
    if debug_iconset.exists():
        print(f"  ℹ  {icon_name}-Debug.appiconset already exists, skipping")
        return False

    print(f"  ✓ Creating {icon_name}-Debug.appiconset with debug overlay")

    # Copy entire iconset
    import shutil
    shutil.copytree(release_iconset, debug_iconset)

    # Process all PNG files in the debug iconset
    for png_file in debug_iconset.glob("*.png"):
        img = Image.open(png_file).convert('RGBA')
        img = add_debug_overlay(img)
        img.save(str(png_file), format='PNG')

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Generate debug app icons with diagonal slash overlay"
    )
    parser.add_argument(
        "assets_path",
        type=str,
        help="Path to Assets.xcassets directory"
    )
    parser.add_argument(
        "--icon-name",
        type=str,
        default="AppIcon",
        help="Name of the app icon set (default: AppIcon)"
    )

    args = parser.parse_args()
    assets_path = Path(args.assets_path)

    if not assets_path.exists():
        print(f"❌ Error: Assets path not found: {assets_path}")
        sys.exit(1)

    if not assets_path.is_dir():
        print(f"❌ Error: Assets path is not a directory: {assets_path}")
        sys.exit(1)

    print(f"\n🎨 Generating debug icons...")
    print(f"   Assets path: {assets_path}")
    print(f"   Icon name: {args.icon_name}")

    # Detect icon type and process
    solidimagestack = assets_path / f"{args.icon_name}.solidimagestack"
    appiconset = assets_path / f"{args.icon_name}.appiconset"

    success = False

    if solidimagestack.exists() or not appiconset.exists():
        # visionOS solid image stack
        success = process_solidimagestack(assets_path, args.icon_name)
    elif appiconset.exists():
        # iOS/macOS appiconset
        success = process_appiconset(assets_path, args.icon_name)
    else:
        # Create both as fallback
        process_appiconset(assets_path, args.icon_name)
        success = True

    if success:
        print(f"\n✅ Debug icons generated successfully!")
        print(f"   You can re-run this script anytime to update debug icons.")
    else:
        print(f"\n✅ Debug icons already exist (no changes made)")


if __name__ == "__main__":
    main()
