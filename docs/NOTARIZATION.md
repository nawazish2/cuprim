# Distributing Cuprim

Cuprim ships outside the Mac App Store. The **free path** is ad-hoc app signing plus Sparkle EdDSA signatures on updates. Developer ID notarization is optional and paid.

## Sparkle updates (free integrity)

Release builds check `SUFeedURL` (GitHub Releases `appcast.xml`), verify the EdDSA signature, then download and install.

- Public key: `SUPublicEDKey` in the packaged Info.plist (`SPARKLE_PUBLIC_ED_KEY` at package time)
- Private key: Keychain only. Generate with Sparkle `generate_keys`; sign artifacts with `sign_update` from `script/release.sh`
- Debug builds skip Sparkle so a debug `.app` is never replaced by a release build

This does **not** remove Gatekeeper on first install. Users still Control-click → Open (or `xattr -cr`) for ad-hoc builds.

## Quick path (you, local testing)

```bash
./script/release.sh
open dist/Cuprim.app
```

Ad-hoc signed. Share the DMG with yourself / testers who know how to right-click → Open past Gatekeeper.

## Public path (anyone can download cleanly)

```
bump version → release.sh with Developer ID → notarize DMG → staple → GitHub Release
```

### Prerequisites

- Apple Silicon Mac + Xcode 26+
- [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
- **Developer ID Application** certificate installed in Keychain  
  (Xcode → Settings → Accounts → Manage Certificates → **+** → Developer ID Application)
- App-specific password for your Apple ID ([appleid.apple.com](https://appleid.apple.com)) **or** an App Store Connect API key

### 1. Bump version

In `script/package_app.sh` (`Info.plist` section):

| Key | Meaning | Example |
|---|---|---|
| `CFBundleShortVersionString` | Marketing version | `0.1.3` |
| `CFBundleVersion` | Build number | `4` |

### 2. Sign and package

```bash
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./script/release.sh
```

Outputs:

- `dist/Cuprim.app`
- `dist/Cuprim-<version>.dmg`
- `dist/Cuprim-<version>.app.zip`

Confirm the app identity:

```bash
codesign -dv --verbose=4 dist/Cuprim.app
spctl --assess --verbose dist/Cuprim.app || true   # may fail until notarized
```

### 3. Notarize the DMG

**Apple ID + app-specific password:**

```bash
xcrun notarytool submit dist/Cuprim-0.1.2.dmg \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait
```

**App Store Connect API key:**

```bash
xcrun notarytool submit dist/Cuprim-0.1.2.dmg \
  --key ~/AuthKey_XXXXXX.p8 \
  --key-id XXXXXX \
  --issuer YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY \
  --wait
```

On success:

```bash
xcrun stapler staple dist/Cuprim-0.1.2.dmg
xcrun stapler validate dist/Cuprim-0.1.2.dmg
```

Optional: also notarize / staple the `.app` inside a zip if you prefer zip-only distribution. DMG + staple is the usual path.

### 4. Publish

```bash
gh release create v0.1.2 \
  dist/Cuprim-0.1.2.dmg \
  dist/Cuprim-0.1.2.app.zip \
  --title "Cuprim 0.1.2" \
  --notes "$(cat <<'EOF'
## What's new
- …

## Requirements
- Apple Silicon
- macOS 26+
EOF
)"
```

### 5. Verify as a new user would

On another Mac (or a clean user account):

1. Download the DMG from the release page
2. Open it — Gatekeeper should allow without “unidentified developer” after notarization
3. Drag to Applications and launch
4. Confirm menu bar gauge + providers

## Ad-hoc vs Developer ID

| | Ad-hoc (`codesign -`) | Developer ID + notarized |
|---|---|---|
| Who can run | You / people who bypass Gatekeeper | Anyone |
| Gatekeeper | Blocks / warns | Trusted |
| Cost | Free | Apple Developer Program |
| Command | `./script/release.sh` | `CODESIGN_IDENTITY=… ./script/release.sh` then notarize |

## Troubleshooting

**`notarytool` rejects the app**  
Often missing Hardened Runtime. `package_app.sh` already passes `--options runtime` when `CODESIGN_IDENTITY` is not `-`. Re-sign and resubmit.

**Users still see “damaged” / can’t open**  
Quarantine attribute from browsers. Stapled notarization usually fixes this; otherwise:

```bash
xattr -cr /Applications/Cuprim.app
```

**Wrong architecture**  
Cuprim is arm64-only. Intel Macs are not supported (`LSRequiresNativeExecution`).

**Version in DMG name is stale**  
`release.sh` reads `CFBundleShortVersionString` from the packaged app. Bump it in `package_app.sh` before releasing.

## Related

- Release script: `script/release.sh`
- App packaging / plist / codesign: `script/package_app.sh`
- Dev loop: `script/build_and_run.sh`
