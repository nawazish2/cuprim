#!/usr/bin/env bash
# Release build: package Cuprim.app + branded DMG + zip for GitHub Releases.
# Optional:
#   CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./script/release.sh
# Sparkle signing uses generate_keys / sign_update from the Sparkle toolchain
# (private key stays in Keychain).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export CONFIG=release
export LAUNCH=0
export CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

mkdir -p "$ROOT/dist"
find "$ROOT/dist" -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +

"$ROOT/script/package_app.sh"

APP_DIR="$ROOT/dist/Cuprim.app"
VERSION="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist" 2>/dev/null || echo "0.1.6"
)"
BUILD="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_DIR/Contents/Info.plist" 2>/dev/null || echo "7"
)"
DMG="$ROOT/dist/Cuprim-${VERSION}.dmg"
ZIP="$ROOT/dist/Cuprim-${VERSION}.app.zip"
STABLE_DMG="$ROOT/dist/Cuprim.dmg"

rm -f "$DMG" "$ZIP" "$STABLE_DMG"

echo "→ Creating branded DMG…"
chmod +x "$ROOT/script/create_dmg.sh" "$ROOT/script/generate_dmg_background.py"
"$ROOT/script/create_dmg.sh" "$APP_DIR" "$DMG"
ln -sfn "$(basename "$DMG")" "$STABLE_DMG"

echo "→ Creating zip…"
(
  cd "$ROOT/dist"
  ditto -c -k --keepParent "Cuprim.app" "Cuprim-${VERSION}.app.zip"
)

if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
  echo "→ Signing DMG…"
  codesign --force --sign "$CODESIGN_IDENTITY" "$DMG"
fi

SIGN_UPDATE="$(find "$ROOT/.build" -name sign_update -type f 2>/dev/null | head -1 || true)"
APPCAST="$ROOT/dist/appcast.xml"
ENCLOSURE_URL="${ENCLOSURE_URL:-https://github.com/nawazish2/cuprim/releases/download/v${VERSION}/Cuprim.dmg}"
LENGTH="$(stat -f%z "$DMG")"
SIGNATURE=""
if [[ -n "$SIGN_UPDATE" ]]; then
  echo "→ Sparkle-signing $DMG…"
  SIGNATURE="$("$SIGN_UPDATE" "$DMG" | sed -n 's/.*edSignature="\([^"]*\)".*/\1/p')"
fi

python3 - <<PY
from datetime import datetime, timezone
from pathlib import Path
signature = """${SIGNATURE}""".strip()
sig_attr = f' sparkle:edSignature="{signature}"' if signature else ""
xml = f'''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Cuprim</title>
    <language>en</language>
    <item>
      <title>Version ${VERSION} (Build ${BUILD})</title>
      <pubDate>{datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")}</pubDate>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>
      <enclosure url="${ENCLOSURE_URL}" type="application/octet-stream" length="${LENGTH}"{sig_attr} />
    </item>
  </channel>
</rss>
'''
Path("$APPCAST").write_text(xml)
print(f"→ Wrote {Path("$APPCAST")}")
PY

if [[ -z "$SIGNATURE" ]]; then
  echo "note: Sparkle signature missing. Run Sparkle generate_keys (Keychain) then sign_update." >&2
fi

cat <<EOF

Release artifacts ready for GitHub Releases:

  $APP_DIR
  $DMG
  $STABLE_DMG
  $ZIP
  $APPCAST

Version: $VERSION ($BUILD)
Signing: $CODESIGN_IDENTITY

Notarization steps: docs/NOTARIZATION.md
EOF
