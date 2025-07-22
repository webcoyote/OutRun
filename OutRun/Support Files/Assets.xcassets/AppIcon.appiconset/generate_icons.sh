#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Generate all iOS app icon sizes from Icon.png using ImageMagick
# Run this script in the AppIcon.appiconset directory

# Check if Icon.png exists
if [ ! -f "Icon.png" ]; then
    echo "Error: Icon.png not found in current directory"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick (magick) is not installed"
    echo "Install with: brew install imagemagick"
    exit 1
fi

echo "Generating app icons from Icon.png..."

# iPhone icons
magick Icon.png -resize 40x40 icon_20pt@2x.png
magick Icon.png -resize 60x60 icon_20pt@3x.png
magick Icon.png -resize 29x29 icon_29pt.png
magick Icon.png -resize 58x58 icon_29pt@2x.png
magick Icon.png -resize 87x87 icon_29pt@3x.png
magick Icon.png -resize 80x80 icon_40pt@2x.png
magick Icon.png -resize 120x120 icon_40pt@3x.png
magick Icon.png -resize 120x120 icon_60pt@2x.png
magick Icon.png -resize 180x180 icon_60pt@3x.png

# iPad icons
magick Icon.png -resize 20x20 icon_20pt.png
magick Icon.png -resize 40x40 icon_40pt.png
magick Icon.png -resize 29x29 icon_29pt-1.png
magick Icon.png -resize 58x58 icon_29pt@2x-1.png
magick Icon.png -resize 40x40 icon_40pt-1.png
magick Icon.png -resize 80x80 icon_40pt@2x-1.png
magick Icon.png -resize 76x76 icon_76pt.png
magick Icon.png -resize 152x152 icon_76pt@2x.png
magick Icon.png -resize 167x167 icon_83.5@2x.png

echo "Icon generation complete!"
