#!/usr/bin/env bash
# Shared Cuprim.app packaging. Sourced or invoked by build_and_run.sh / release.sh.
# Env:
#   CONFIG=debug|release   (default: debug)
#   CODESIGN_IDENTITY=...  (default: "-" ad-hoc)
#   LAUNCH=1               (open the app after packaging)
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

echo "→ Building ($CONFIG, arm64)…"
swift build -c "$CONFIG" --arch arm64

BIN_DIR="$(swift build -c "$CONFIG" --arch arm64 --show-bin-path)"
BIN="$BIN_DIR/Cuprim"
APP_DIR="$ROOT/dist/Cuprim.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RES"

cp "$BIN" "$MACOS/Cuprim"
chmod +x "$MACOS/Cuprim"

# Resource fallbacks for Bundle.main
if [ -d "Sources/Cuprim/Resources/ProviderIcons" ]; then
  mkdir -p "$RES/ProviderIcons"
  cp -R Sources/Cuprim/Resources/ProviderIcons/* "$RES/ProviderIcons/" 2>/dev/null || true
fi
if [ -d "Sources/Cuprim/Resources/MenuBar" ]; then
  mkdir -p "$RES/MenuBar"
  cp -R Sources/Cuprim/Resources/MenuBar/* "$RES/MenuBar/" 2>/dev/null || true
fi
if [ -d "Sources/Cuprim/Resources/AppIcon/AppIcon.icon" ]; then
  rm -rf "$RES/AppIcon.icon"
  cp -R "Sources/Cuprim/Resources/AppIcon/AppIcon.icon" "$RES/AppIcon.icon"
fi
if [ -f "Sources/Cuprim/Resources/AppIcon/AppIcon.icns" ]; then
  cp "Sources/Cuprim/Resources/AppIcon/AppIcon.icns" "$RES/AppIcon.icns"
fi
if [ -f "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" ]; then
  cp "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" "$RES/AppIcon-1024.png"
fi
if [ -f "Sources/Cuprim/Resources/AppIcon/AppIcon-About.png" ]; then
  mkdir -p "$RES/AppIcon"
  cp "Sources/Cuprim/Resources/AppIcon/AppIcon-About.png" "$RES/AppIcon/AppIcon-About.png"
  cp "Sources/Cuprim/Resources/AppIcon/AppIcon-1024.png" "$RES/AppIcon/AppIcon-1024.png" 2>/dev/null || true
fi

if command -v lipo >/dev/null 2>&1; then
  ARCHS="$(lipo -archs "$MACOS/Cuprim" 2>/dev/null || true)"
  if [[ -n "$ARCHS" && "$ARCHS" != *arm64* ]]; then
    echo "error: binary is not arm64 (got: $ARCHS)" >&2
    exit 1
  fi
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
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
	<string>7</string>
	<key>CFBundleShortVersionString</key>
	<string>0.1.6</string>
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
	<!-- Show in Dock with AppIcon; menu bar status item still works. -->
	<key>LSUIElement</key>
	<false/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
	<key>NSPrincipalClass</key>
	<string>CuprimApplication</string>
</dict>
</plist>
PLIST

echo "→ Signing (identity: $CODESIGN_IDENTITY)…"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true
else
  codesign --force --deep --options runtime --sign "$CODESIGN_IDENTITY" "$APP_DIR"
  codesign --verify --verbose=2 "$APP_DIR"
fi

echo "✓ Packaged $APP_DIR"

if [[ "$LAUNCH" == "1" ]]; then
  echo "Launching $APP_DIR (arm64 · macOS 26+ · Liquid Glass)"
  open "$APP_DIR"
fi
