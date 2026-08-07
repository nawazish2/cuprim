---
name: verify-tokenbar
description: "Verify TokenBar (macOS menu-bar quota tracker) by building/packaging the Swift app, running TokenBarCore tests, and capturing evidence. Use when proving TokenBar changes, after UI/provider/settings work, or when asked to verify the app. Menu-bar automation is limited — prefer build + package + manual UI checks."
---

# Verify TokenBar

Drive TokenBar the way a user would on **Apple Silicon macOS 26+**. This is a native menu-bar app (AppKit status item + SwiftUI panels). There is no web UI, no CLI TUI, and no browser harness.

**Hard precondition:** `uname -m` is `arm64` and the host is macOS 26+. Linux / Intel / cloud VMs cannot build or launch the app — report that and stop rather than inventing substitutes.

## Launch

From the repo root:

```bash
./script/build_and_run.sh
```

That runs `script/package_app.sh` with `CONFIG=debug` and `LAUNCH=1`, producing `dist/TokenBar.app` and opening it.

Package without launching:

```bash
CONFIG=debug LAUNCH=0 ./script/package_app.sh
# or release:
CONFIG=release LAUNCH=0 ./script/package_app.sh
```

Ready when:

- `swift build` / packaging finishes with exit `0`
- `dist/TokenBar.app/Contents/MacOS/TokenBar` exists
- The gauge appears in the menu bar (user-visible; not reliably scriptable)

Teardown (only what this run started):

```bash
# Prefer quitting via the app menu: TokenBar → Quit TokenBar (⌘Q)
# Or, if this run opened the packaged app and you know its PID:
osascript -e 'tell application "TokenBar" to quit' 2>/dev/null || true
```

Do **not** `killall TokenBar` if a user may already be running their own copy. If unsure whether the process is yours, leave it running and note that in the proof.

## Doctor

Run before driving UI, and again if anything looks off:

```bash
uname -m                                          # must be arm64
sw_vers -productVersion                           # must be 26.x+
swift --version
swift build -c debug --arch arm64
swift test
test -x dist/TokenBar.app/Contents/MacOS/TokenBar \
  || CONFIG=debug LAUNCH=0 ./script/package_app.sh
plutil -p dist/TokenBar.app/Contents/Info.plist | egrep 'CFBundleShortVersionString|CFBundleIdentifier|LSMinimumSystemVersion'
codesign -dv dist/TokenBar.app 2>&1 | head -20
pgrep -lf '/TokenBar.app/Contents/MacOS/TokenBar' || true
```

Healthy instance checklist:

- Architecture arm64; macOS ≥ 26
- `swift build` and `swift test` exit 0
- Packaged app exists with bundle id `com.nawazish.tokenbar`
- If you need a live UI, the process path is **this repo’s** `dist/TokenBar.app/...`, not `/Applications/TokenBar.app`, unless you intentionally installed there

Refuse to “verify” against a random already-running TokenBar you did not start for this run when the claim depends on your build.

## Drive

**Automation ceiling:** `NSStatusItem` menus and menu-bar extras are poorly exposed to Accessibility/AppleScript. Do **not** pretend coordinate-clicking the menu bar is reliable CI.

### What CAN be verified (scripted / semi-scripted)

| Check | How |
|-------|-----|
| Core logic | `swift test` (TokenBarCore: utilization, formatting, classifiers) |
| Compiles | `swift build -c debug --arch arm64` (and release if shipping) |
| Packages | `CONFIG=debug LAUNCH=0 ./script/package_app.sh` → `dist/TokenBar.app` |
| Info.plist / version | `plutil` / `PlistBuddy` on packaged app |
| Ad-hoc sign | `codesign -dv dist/TokenBar.app` |
| Open Settings window | After launch: `osascript -e 'tell application "TokenBar" to activate'` then send ⌘, **if** the app accepts it; otherwise open via status menu → **Settings…** (manual) |
| Open About | App menu **About TokenBar** or status menu (manual / light AppleScript activate) |
| Release packaging | `./script/release.sh` (produces DMG + zip; slow; don’t run unless the claim needs it) |

### What is MANUAL (required for UI claims)

- Menu-bar gauge appears and updates
- Status menu **Usage** rows / empty “No providers signed in”
- **Show TokenBar** glass dashboard panel
- Provider tabs, refresh (⌘R), Settings toggles/reorder
- **Share Screenshot** → provider submenu → pasteboard + target app activate
- **Check for Updates…** dialogs (hits GitHub Releases network)
- First-open Gatekeeper behavior for ad-hoc builds

When proving a UI feature, follow the matching file under [`features/`](features/). Capture screenshots manually (⌘⇧4 or Screenshot app) into the evidence path below. State clearly: `manual UI` vs `scripted build`.

### Isolation

Only one menu-bar TokenBar should own the status item. Do not launch a second copy alongside the user’s installed app without quitting yours first. Prefer driving `dist/TokenBar.app` from this checkout.

## Evidence

Put artifacts under:

```
.cursor/skills/verify-tokenbar/evidence/<claim-slug>/
```

Suggested files:

- `swift-build.log` — `swift build -c debug --arch arm64` transcript
- `swift-test.log` — `swift test` transcript
- `package.log` — packaging transcript
- `doctor.txt` — uname / sw_vers / codesign / plist snippets
- `ui-*.png` — manual screenshots (menu open, dashboard, settings, about, share card)
- `NOTES.md` — claim, entry point, scripted vs manual, result

Proof standards:

- Exercise the real user path for UI claims (status menu / Settings), not only unit tests
- For logic-only changes in `TokenBarCore`, `swift test` + successful package is enough
- Capture action + resulting state (e.g. Settings toggle + menu reflecting order)
- Do not mock provider APIs unless the change is explicitly behind a test double that already exists — this app reads real local credentials
- Evidence survives cleanup

## Cleanup

- Quit only the TokenBar instance **this run** started (AppleScript quit or PID you recorded)
- Never `killall` by name if you cannot tell user vs verify instance apart
- Do not delete `dist/` evidence copies you moved into `evidence/`; you may leave `dist/TokenBar.app` as a cache
- Never delete `evidence/` during teardown
- Do not uninstall `/Applications/TokenBar.app` or clear user preferences/login items

## Feature map

Index: [`features/README.md`](features/README.md)

| Feature | File |
|---------|------|
| Menu-bar status | [`features/menu-bar-status.md`](features/menu-bar-status.md) |
| Dashboard panel | [`features/dashboard-panel.md`](features/dashboard-panel.md) |
| Settings | [`features/settings.md`](features/settings.md) |
| Share screenshot | [`features/share-screenshot.md`](features/share-screenshot.md) |
| Check for updates | [`features/check-for-updates.md`](features/check-for-updates.md) |
| About | [`features/about.md`](features/about.md) |

Keep the map honest with `/maintain-verification-skill` when UI entry points change.
