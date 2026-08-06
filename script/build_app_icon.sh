#!/usr/bin/env bash
# Rebuild TokenBar AppIcon.icon exports + AppIcon.icns via Apple ictool.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON="$ROOT/Sources/TokenBar/Resources/AppIcon/AppIcon.icon"
OUT="$ROOT/Design/AppIcon/Exports"
RES_ICON="$ROOT/Sources/TokenBar/Resources/AppIcon"
ICTOOL=""
for c in \
  "/Applications/Xcode-beta.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" \
  "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" \
  "/Applications/Xcode-beta.app/Contents/Developer/usr/bin/ictool"
do
  [ -x "$c" ] && ICTOOL="$c" && break
done
if [ -z "$ICTOOL" ]; then
  echo "error: ictool not found (need Xcode with Icon Composer)" >&2
  exit 1
fi
mkdir -p "$OUT"
"$ICTOOL" "$ICON" --export-image --output-file "$OUT/TokenBar-Default-1024.png" \
  --platform macOS --rendition Default --width 1024 --height 1024 --scale 1 --design-generation 26 >/dev/null
cp "$OUT/TokenBar-Default-1024.png" "$RES_ICON/AppIcon-1024.png"
MASTER="$OUT/TokenBar-Default-1024.png"
ICONSET="$RES_ICON/AppIcon.iconset"
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
for spec in \
  "16:icon_16x16.png" "32:icon_16x16@2x.png" "32:icon_32x32.png" "64:icon_32x32@2x.png" \
  "128:icon_128x128.png" "256:icon_128x128@2x.png" "256:icon_256x256.png" \
  "512:icon_256x256@2x.png" "512:icon_512x512.png" "1024:icon_512x512@2x.png"
do
  size="${spec%%:*}"; name="${spec##*:}"
  sips -z "$size" "$size" "$MASTER" --out "$ICONSET/$name" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RES_ICON/AppIcon.icns"
rm -rf "$ICONSET"
echo "App icon rebuilt: $RES_ICON/AppIcon.icns + AppIcon.icon"
