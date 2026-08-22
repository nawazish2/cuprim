#!/usr/bin/env bash
# Shared Cuprim.app packaging. Sourced or invoked by build_and_run.sh / release.sh.
# Env:
#   CONFIG=debug|release   (default: debug)
#   CODESIGN_IDENTITY=...  (default: "-" ad-hoc)
#   LAUNCH=1               (open the app after packaging)
#   SPARKLE_PUBLIC_ED_KEY  (optional EdDSA public key for Sparkle)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  echo "error: Cuprim requires Apple Silicon (arm64). This Mac is $ARCH." >&2
  exit 1
fi

CONFIG="${CONFIG:-debug}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
LAUNCH="${LAUNCH:-0}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"
SU_FEED_URL="${SU_FEED_URL:-https://github.com/nawazish2/cuprim/releases/latest/download/appcast.xml}"

echo "→ Building ($CONFIG, arm64)…"
swift build -c "$CONFIG" --arch arm64

BIN_DIR="$(swift build -c "$CONFIG" --arch arm64 --show-bin-path)"
BIN="$BIN_DIR/Cuprim"
APP_DIR="$ROOT/dist/Cuprim.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"
FRAMEWORKS="$CONTENTS/Frameworks"

require_dir() {
  if [[ ! -d "$1" ]]; then
    echo "error: missing required directory: $1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "error: missing required file: $1" >&2
    exit 1
  fi
}

require_file "$BIN"
require_dir "Sources/Cuprim/Resources/ProviderIcons"
require_dir "Sources/Cuprim/Resources/MenuBar"
require_file "Sources/Cuprim/Resources/AppIcon/AppIcon.icns"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RES" "$FRAMEWORKS"

cp "$BIN" "$MACOS/Cuprim"
chmod +x "$MACOS/Cuprim"

mkdir -p "$RES/ProviderIcons"
cp -R Sources/Cuprim/Resources/ProviderIcons/. "$RES/ProviderIcons/"
mkdir -p "$RES/MenuBar"
cp -R Sources/Cuprim/Resources/MenuBar/. "$RES/MenuBar/"

if [[ -d "Sources/Cuprim/Resources/AppIcon/AppIcon.icon" ]]; then
  rm -rf "$RES/AppIcon.icon"
  cp -R "Sources/Cuprim/Resources/AppIcon/AppIcon.icon" "$RES/AppIcon.icon"
fi
cp "Sources/Cuprim/Resources/AppIcon/AppIcon.icns" "$RES/AppIcon.icns"
if [[ -f "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" ]]; then
  cp "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" "$RES/AppIcon-1024.png"
fi
if [[ -f "Sources/Cuprim/Resources/AppIcon/AppIcon-About.png" ]]; then
  mkdir -p "$RES/AppIcon"
  cp "Sources/Cuprim/Resources/AppIcon/AppIcon-About.png" "$RES/AppIcon/AppIcon-About.png"
  if [[ -f "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" ]]; then
    cp "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" "$RES/AppIcon/AppIcon-1024.png"
  fi
fi

SPARKLE_SRC="$(find "$BIN_DIR" "$ROOT/.build" -name 'Sparkle.framework' -type d 2>/dev/null | head -1 || true)"
if [[ -z "$SPARKLE_SRC" ]]; then
  echo "error: Sparkle.framework not found after build" >&2
  exit 1
fi
ditto "$SPARKLE_SRC" "$FRAMEWORKS/Sparkle.framework"

python3 - "$MACOS/Cuprim" <<'PY'
import subprocess
import sys
from pathlib import Path

binary = Path(sys.argv[1])
out = subprocess.check_output(["otool", "-l", str(binary)], text=True)
rpaths = []
lines = out.splitlines()
for i, line in enumerate(lines):
    if "LC_RPATH" in line:
        for follow in lines[i : i + 6]:
            follow = follow.strip()
            if follow.startswith("path "):
                rpaths.append(follow.split(" ", 1)[1].split(" (", 1)[0])
                break
keep = "@executable_path/../Frameworks"
if keep not in rpaths:
    subprocess.check_call(["install_name_tool", "-add_rpath", keep, str(binary)])
for path in rpaths:
    if path != keep:
        subprocess.run(["install_name_tool", "-delete_rpath", path, str(binary)], check=False)
PY

if command -v lipo >/dev/null 2>&1; then
  ARCHS="$(lipo -archs "$MACOS/Cuprim" 2>/dev/null || true)"
  if [[ -n "$ARCHS" && "$ARCHS" != *arm64* ]]; then
    echo "error: binary is not arm64 (got: $ARCHS)" >&2
    exit 1
  fi
fi

python3 - <<PY
from pathlib import Path
feed = """${SU_FEED_URL}"""
key = """${SPARKLE_PUBLIC_ED_KEY}"""
plist = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>Cuprim</string>
	<key>CFBundleDisplayName</key>
	<string>Cuprim</string>
	<key>CFBundleIdentifier</key>
	<string>com.nawazish.cuprim</string>
	<key>CFBundleVersion</key>
	<string>10</string>
	<key>CFBundleShortVersionString</key>
	<string>0.2.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleExecutable</key>
	<string>Cuprim</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>
	<key>LSMinimumSystemVersion</key>
	<string>26.0</string>
	<key>LSRequiresNativeExecution</key>
	<true/>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSUserNotificationUsageDescription</key>
	<string>Cuprim can notify you when a quota is almost gone. Alerts stay on this Mac.</string>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
	<key>NSPrincipalClass</key>
	<string>CuprimApplication</string>
	<key>SUFeedURL</key>
	<string>{feed}</string>
	<key>SUPublicEDKey</key>
	<string>{key}</string>
	<key>SUEnableAutomaticChecks</key>
	<true/>
	<key>SUAutomaticallyUpdate</key>
	<true/>
	<key>SUEnableInstallerLauncherService</key>
	<true/>
</dict>
</plist>
'''
Path("$CONTENTS/Info.plist").write_text(plist)
PY

echo "→ Signing (identity: $CODESIGN_IDENTITY)…"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_DIR" || {
    echo "error: ad-hoc signing failed" >&2
    exit 1
  }
else
  codesign --force --deep --options runtime --sign "$CODESIGN_IDENTITY" "$APP_DIR" || {
    echo "error: Developer ID signing failed" >&2
    exit 1
  }
fi
codesign --verify --verbose=2 "$APP_DIR" || {
  echo "error: signature verification failed" >&2
  exit 1
}

/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$CONTENTS/Info.plist" >/dev/null
/usr/libexec/PlistBuddy -c 'Print :SUFeedURL' "$CONTENTS/Info.plist" >/dev/null
test -d "$FRAMEWORKS/Sparkle.framework"
file "$MACOS/Cuprim" | grep -q 'arm64'

echo "✓ Packaged $APP_DIR"

if [[ "$LAUNCH" == "1" ]]; then
  echo "Launching $APP_DIR (arm64 · macOS 26+ · Liquid Glass)"
  open "$APP_DIR"
fi
