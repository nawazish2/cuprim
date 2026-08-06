#!/usr/bin/env bash
# Release build: package TokenBar.app + DMG + zip for GitHub Releases.
# Optional:
#   CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./script/release.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export CONFIG=release
export LAUNCH=0
export CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

"$ROOT/script/package_app.sh"

APP_DIR="$ROOT/dist/TokenBar.app"
VERSION="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist" 2>/dev/null || echo "0.1.2"
)"
STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/TokenBar-${VERSION}.dmg"
ZIP="$ROOT/dist/TokenBar-${VERSION}.app.zip"

rm -rf "$STAGE" "$DMG" "$ZIP"
mkdir -p "$STAGE"
cp -R "$APP_DIR" "$STAGE/TokenBar.app"
ln -s /Applications "$STAGE/Applications"

echo "→ Creating DMG…"
hdiutil create \
  -volname "TokenBar" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG" >/dev/null

rm -rf "$STAGE"

echo "→ Creating zip…"
(
  cd "$ROOT/dist"
  ditto -c -k --keepParent "TokenBar.app" "TokenBar-${VERSION}.app.zip"
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
