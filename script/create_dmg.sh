#!/usr/bin/env bash
# Build a branded drag-to-Applications DMG (VS Code–style layout).
# Usage: ./script/create_dmg.sh /path/to/TokenBar.app /path/to/out.dmg
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="${1:?app path required}"
DMG_OUT="${2:?output dmg path required}"
VOL_NAME="TokenBar"
STAGE="$ROOT/dist/dmg-stage"
RW_DMG="$ROOT/dist/.TokenBar-rw.dmg"
VOL_PATH="/Volumes/${VOL_NAME}"
BG_SRC="$ROOT/Design/DMG/background.png"

if [[ ! -d "$APP_SRC" ]]; then
  echo "error: app not found: $APP_SRC" >&2
  exit 1
fi

echo "→ Generating DMG background…"
python3 "$ROOT/script/generate_dmg_background.py"

# Detach any leftover volume from a previous failed run.
if [[ -d "$VOL_PATH" ]]; then
  hdiutil detach "$VOL_PATH" -force >/dev/null 2>&1 || true
fi

rm -rf "$STAGE" "$RW_DMG"
rm -f "$DMG_OUT"
mkdir -p "$STAGE/.background"

cp -R "$APP_SRC" "$STAGE/TokenBar.app"
ln -s /Applications "$STAGE/Applications"
cp "$BG_SRC" "$STAGE/.background/background.png"

echo "→ Creating read-write DMG…"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDRW \
  -fs HFS+ \
  "$RW_DMG" >/dev/null

echo "→ Mounting…"
hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG" >/dev/null

cleanup() {
  if [[ -d "$VOL_PATH" ]]; then
    hdiutil detach "$VOL_PATH" -force >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Wait until the volume is visible to Finder.
for _ in $(seq 1 30); do
  if [[ -d "$VOL_PATH/TokenBar.app" ]]; then
    break
  fi
  sleep 0.2
done
if [[ ! -d "$VOL_PATH/TokenBar.app" ]]; then
  echo "error: volume did not mount at $VOL_PATH" >&2
  exit 1
fi

sleep 1

echo "→ Applying Finder layout…"
osascript <<EOF
tell application "Finder"
  tell disk "$VOL_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 860, 520}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 128
    set background picture of opts to file ".background:background.png"
    -- Leave a clear center lane for the meter→arrow graphic
    set position of item "TokenBar.app" of container window to {150, 185}
    set position of item "Applications" of container window to {510, 185}
    update without registering applications
    delay 1
    close
    open
    delay 1
    set the bounds of container window to {200, 120, 860, 520}
    close
  end tell
end tell
EOF

sync
sleep 1

echo "→ Converting to compressed DMG…"
cleanup
trap - EXIT

# Ensure detached before convert.
if [[ -d "$VOL_PATH" ]]; then
  hdiutil detach "$VOL_PATH" -force >/dev/null 2>&1 || true
fi

hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT" >/dev/null
rm -f "$RW_DMG"
rm -rf "$STAGE"

echo "✓ DMG ready: $DMG_OUT"
