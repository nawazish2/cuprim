#!/usr/bin/env bash
# Open Apple Icon Composer with Cuprim square layers (macOS 26 standard workflow).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LAYERS="$ROOT/Design/AppIcon/Layers"
ICON="$ROOT/Sources/Cuprim/Resources/AppIcon/AppIcon.icon"

ICON_COMPOSER=""
for c in \
  "/Applications/Xcode-beta.app/Contents/Applications/Icon Composer.app" \
  "/Applications/Xcode.app/Contents/Applications/Icon Composer.app" \
  "/Applications/Icon Composer.app"
do
  if [ -d "$c" ]; then ICON_COMPOSER="$c"; break; fi
done

if [ -z "$ICON_COMPOSER" ]; then
  echo "Icon Composer not found."
  echo "Install Xcode 26+ or download from: https://developer.apple.com/icon-composer/"
  exit 1
fi

echo "=== Cuprim → Icon Composer (Apple standard) ==="
echo ""
echo "Layers (square, unmasked — do NOT round corners yourself):"
echo "  Background: $LAYERS/Background.png"
echo "  Foreground: $LAYERS/Foreground.png"
echo ""
echo "Steps:"
echo "  1. Icon Composer opens."
echo "  2. File → Open (or drag) this package:"
echo "       $ICON"
echo "     Or: File → New, then import layers."
echo "  3. Drag Background.png as the BACKGROUND layer (full-bleed square)."
echo "  4. Drag Foreground.png as the FOREGROUND layer (gauge)."
echo "  5. Let the system mask corners — keep layers square."
echo "  6. Annotate Default / Dark / Clear / Tinted appearances."
echo "  7. File → Save into:"
echo "       $ICON"
echo "  8. Optional: export flattened PNG for marketing."
echo "  9. Run: ./script/build_and_run.sh"
echo ""
echo "Docs: https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer"
echo ""

open -a "$ICON_COMPOSER"
open "$LAYERS"
# Reveal the .icon package in Finder
open -R "$ICON"

echo "Opened Icon Composer + Layers folder."
echo "After saving AppIcon.icon, rebuild Cuprim."
