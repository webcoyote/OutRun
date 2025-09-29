#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Generate all iOS app icon sizes from Icon.png using ImageMagick
# Run this script in the AppIcon.appiconset directory

# Check if Icon.png exists
if [[ ! -f "Icon.png" ]]; then
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

# Watch app icons
WATCH_DIR="../../../../OutRun Watch App/Assets.xcassets/AppIcon.appiconset"
if [[ -d "$WATCH_DIR" ]]; then
    echo "Generating watch app icons..."
    
    # Notification Center icons
    magick Icon.png -resize 48x48 "$WATCH_DIR/icon_24pt@2x_38mm.png"
    magick Icon.png -resize 55x55 "$WATCH_DIR/icon_27.5pt@2x_42mm.png"
    magick Icon.png -resize 66x66 "$WATCH_DIR/icon_33pt@2x_45mm.png"
    
    # Companion Settings icons
    magick Icon.png -resize 58x58 "$WATCH_DIR/icon_29pt@2x.png"
    magick Icon.png -resize 87x87 "$WATCH_DIR/icon_29pt@3x.png"
    
    # App Launcher icons
    magick Icon.png -resize 80x80 "$WATCH_DIR/icon_40pt@2x_38mm.png"
    magick Icon.png -resize 88x88 "$WATCH_DIR/icon_44pt@2x_40mm.png"
    magick Icon.png -resize 92x92 "$WATCH_DIR/icon_46pt@2x_41mm.png"
    magick Icon.png -resize 100x100 "$WATCH_DIR/icon_50pt@2x_44mm.png"
    magick Icon.png -resize 102x102 "$WATCH_DIR/icon_51pt@2x_45mm.png"
    magick Icon.png -resize 108x108 "$WATCH_DIR/icon_54pt@2x_49mm.png"
    
    # Quick Look icons
    magick Icon.png -resize 172x172 "$WATCH_DIR/icon_86pt@2x_38mm.png"
    magick Icon.png -resize 196x196 "$WATCH_DIR/icon_98pt@2x_42mm.png"
    magick Icon.png -resize 216x216 "$WATCH_DIR/icon_108pt@2x_44mm.png"
    magick Icon.png -resize 234x234 "$WATCH_DIR/icon_117pt@2x_45mm.png"
    magick Icon.png -resize 258x258 "$WATCH_DIR/icon_129pt@2x_49mm.png"
    
    # App Store icon
    magick Icon.png -resize 1024x1024 "$WATCH_DIR/icon_1024pt.png"
else
    echo "Watch app directory not found, skipping watch icons"
fi

# Widget app icon
WIDGET_DIR="../../../../OutRunWidgets/Assets.xcassets/AppIcon.appiconset"
if [[ -d "$WIDGET_DIR" ]]; then
    echo "Generating widget app icon..."
    
    # Widget icon (1024x1024 for watchOS universal)
    magick Icon.png -resize 1024x1024 "$WIDGET_DIR/icon_1024pt.png"
else
    echo "Widget directory not found, skipping widget icon"
fi

echo "Icon generation complete!"
