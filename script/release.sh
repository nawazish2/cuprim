#!/usr/bin/env bash
# Release build: package Cuprim.app + branded DMG + zip for GitHub Releases.
# Optional:
#   CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./script/release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export CONFIG=release
export LAUNCH=0
export CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

# Fresh release directory — drop stale apps/artifacts from older names or builds.
mkdir -p "$ROOT/dist"
find "$ROOT/dist" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +

"$ROOT/script/package_app.sh"

APP_DIR="$ROOT/dist/Cuprim.app"
VERSION="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist" 2>/dev/null || echo "0.1.3"
)"
DMG="$ROOT/dist/Cuprim-${VERSION}.dmg"
ZIP="$ROOT/dist/Cuprim-${VERSION}.app.zip"

rm -f "$DMG" "$ZIP"

echo "→ Creating branded DMG…"
chmod +x "$ROOT/script/create_dmg.sh" "$ROOT/script/generate_dmg_background.py"
"$ROOT/script/create_dmg.sh" "$APP_DIR" "$DMG"

echo "→ Creating zip…"
(
  cd "$ROOT/dist"
  ditto -c -k --keepParent "Cuprim.app" "Cuprim-${VERSION}.app.zip"
)

if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
  echo "→ Signing DMG…"
  codesign --force --sign "$CODESIGN_IDENTITY" "$DMG" || true
fi

cat <<EOF

Release artifacts ready for GitHub Releases:

  $APP_DIR
  $DMG
  $ZIP

Version: $VERSION
Signing: $CODESIGN_IDENTITY

Notarization steps: docs/NOTARIZATION.md
EOF
