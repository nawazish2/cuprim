#!/usr/bin/env bash
# Rebuild TokenBar app icon via Apple Icon Composer (ictool) → Finder/Dock/About.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON="$ROOT/Sources/TokenBar/Resources/AppIcon/AppIcon.icon"
LAYERS="$ROOT/Design/AppIcon/Layers"
ASSETS="$ICON/Assets"
EXPORTS="$ROOT/Design/AppIcon/Exports"
RES="$ROOT/Sources/TokenBar/Resources/AppIcon"

ICTOOL=""
for c in \
  "/Applications/Xcode-beta.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" \
  "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool"
do
  if [ -x "$c" ]; then ICTOOL="$c"; break; fi
done
if [ -z "$ICTOOL" ]; then
  echo "error: ictool not found (need Xcode 26+ Icon Composer)" >&2
  exit 1
fi

mkdir -p "$EXPORTS" "$ASSETS"
# Keep Icon Composer package assets in sync with Design layers
if [ -f "$LAYERS/Background.png" ] && [ -f "$LAYERS/Foreground.png" ]; then
  cp "$LAYERS/Background.png" "$ASSETS/Background.png"
  cp "$LAYERS/Foreground.png" "$ASSETS/Foreground.png"
fi

echo "→ Exporting Liquid Glass renders with Icon Composer…"
"$ICTOOL" "$ICON" --export-image --output-file "$EXPORTS/TokenBar-Default-1024.png" \
  --platform macOS --rendition Default --width 1024 --height 1024 --scale 1 --design-generation 26
"$ICTOOL" "$ICON" --export-image --output-file "$EXPORTS/TokenBar-Dark-1024.png" \
  --platform macOS --rendition Dark --width 1024 --height 1024 --scale 1 --design-generation 26

cp "$EXPORTS/TokenBar-Default-1024.png" "$RES/AppIcon-1024.png"
cp "$EXPORTS/TokenBar-Default-1024.png" "$RES/AppIcon-About.png"

ICONSET="$RES/AppIcon.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
python3 <<'PY'
from PIL import Image
from pathlib import Path
master = Image.open("/Users/nawazish/Developer/tokenbar/Sources/TokenBar/Resources/AppIcon/AppIcon-1024.png").convert("RGBA")
out = Path("/Users/nawazish/Developer/tokenbar/Sources/TokenBar/Resources/AppIcon/AppIcon.iconset")
for name, size in [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]:
    master.resize((size, size), Image.Resampling.LANCZOS).save(out / name, format="PNG")
PY
xcrun iconutil -c icns "$ICONSET" -o "$RES/AppIcon.icns"
rm -rf "$ICONSET"

echo "✓ Icon Composer export → AppIcon.icns + AppIcon.icon"
echo "  Tweak visually: ./script/open_icon_composer.sh"
echo "  Then re-run this script and ./script/build_and_run.sh"
