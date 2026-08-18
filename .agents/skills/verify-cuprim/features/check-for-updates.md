# Check for updates

Release builds use Sparkle to fetch, verify, download, and install updates. Debug builds skip Sparkle and say so.

## Sub-features

- `updates-entry` exposes **Check for Updates…** from the app menu and Settings → About and updates
- `updates-uptodate` tells the user they are already on the latest
- `updates-available` verifies and installs when a newer signed feed item exists
- `updates-debug` explains that debug builds do not check

## How to get to it (user POV)

- App menu → **Check for Updates…**
- Settings → About and updates → **Check for Updates…**

## Driving it with verify-cuprim

- Live instance; network available for a real check
- Current version is whatever is in the packaged Info.plist (do not bump for verify)
- **Debug (this repo’s usual package).** Expect the debug explanation dialog.
- **Release only** for a real Sparkle install. Do not install mid-run unless the claim is the installer path.

## Gotchas

- Sparkle is skipped in DEBUG
- Private EdDSA keys stay in Keychain; `SUPublicEDKey` is packaged
- Installing an update mid-run invalidates the `dist/` binary you were proving
