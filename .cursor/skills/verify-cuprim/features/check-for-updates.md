# Check for updates

Check for Updates talks to GitHub Releases, compares marketing versions, and can download/install a newer zip when the user confirms.

## Sub-features

- `updates-entry` exposes **Check for Updates…** from the status menu, app menu, and Settings About group
- `updates-uptodate` shows “You’re up to date” when remote ≤ current
- `updates-available` offers download/install when remote is newer (destructive to the running app — avoid unless intentional)
- `updates-error` surfaces a failure dialog when the network/API fails

## How to get to it (user POV)

- Status menu → **Check for Updates…**
- App menu → **Check for Updates…**
- Settings → About → **Check for Updates…**

## Driving it with verify-cuprim

Preconditions:

- Live instance; network available for a real check
- Current version is whatever is in the packaged Info.plist (do not bump for verify)

- **Safe check (manual).** Choose **Check for Updates…**. Progress UI may appear (“Checking for updates…”).
- **Up to date / error (manual).** Prefer proving the dialog text. Screenshot → `ui-updates.png`. Record current vs remote in `NOTES.md`.
- **Do not install** a newer build during routine verification unless the claim is specifically about the installer path — install relaunches and replaces the app.

## Gotchas

- Offline or API errors are valid outcomes; capture the error dialog rather than retrying forever
- Installing an update mid-run invalidates the `dist/` binary you were proving — start over after
- Version source of truth for packaging is `script/package_app.sh`, not a bumped git tag alone
