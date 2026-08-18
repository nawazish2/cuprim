---
name: verify-cuprim
description: "Verify Cuprim (macOS menu-bar quota tracker) by building/packaging the Swift app, running CuprimCore tests, and capturing evidence. Use when proving Cuprim changes, after UI/provider/settings work, or when asked to verify the app. Menu-bar automation is limited — prefer build + package + manual UI checks."
---

# Verify Cuprim

Drive Cuprim the way a user would on **Apple Silicon macOS 26+**. This is a native menu-bar app (AppKit status item + SwiftUI panels). There is no web UI, no CLI TUI, and no browser harness.

**Hard precondition:** `uname -m` is `arm64` and the host is macOS 26+. Linux / Intel / cloud VMs cannot build or launch the app — report that and stop rather than inventing substitutes.

## Launch

From the repo root:

```bash
./script/build_and_run.sh
```

That runs `script/package_app.sh` with `CONFIG=debug` and `LAUNCH=1`, producing `dist/Cuprim.app` and opening it.

Package without launching:

```bash
CONFIG=debug LAUNCH=0 ./script/package_app.sh
# or release:
CONFIG=release LAUNCH=0 ./script/package_app.sh
```

Ready when:

- `swift build` / packaging finishes with exit `0`
- `dist/Cuprim.app/Contents/MacOS/Cuprim` exists
- The gauge appears in the menu bar (user-visible; not reliably scriptable)

Teardown (only what this run started):

```bash
# Prefer quitting via the app menu: Cuprim → Quit Cuprim (⌘Q)
# Or, if this run opened the packaged app and you know its PID:
osascript -e 'tell application "Cuprim" to quit' 2>/dev/null || true
```

Do **not** `killall Cuprim` if a user may already be running their own copy. If unsure whether the process is yours, leave it running and note that in the proof.

## Doctor

Run before driving UI, and again if anything looks off:

```bash
uname -m                                          # must be arm64
sw_vers -productVersion                           # must be 26.x+
swift --version
swift build -c debug --arch arm64
swift test
test -x dist/Cuprim.app/Contents/MacOS/Cuprim \
  || CONFIG=debug LAUNCH=0 ./script/package_app.sh
plutil -p dist/Cuprim.app/Contents/Info.plist | egrep 'CFBundleShortVersionString|CFBundleIdentifier|LSMinimumSystemVersion'
codesign -dv dist/Cuprim.app 2>&1 | head -20
pgrep -lf '/Cuprim.app/Contents/MacOS/Cuprim' || true
```

Healthy instance checklist:

- Architecture arm64; macOS ≥ 26
- `swift build` and `swift test` exit 0
- Packaged app exists with bundle id `com.nawazish.cuprim`
- If you need a live UI, the process path is **this repo’s** `dist/Cuprim.app/...`, not `/Applications/Cuprim.app`, unless you intentionally installed there

Refuse to “verify” against a random already-running Cuprim you did not start for this run when the claim depends on your build.

## Drive

**Automation ceiling:** `NSStatusItem` menus and menu-bar extras are poorly exposed to Accessibility/AppleScript. Do **not** pretend coordinate-clicking the menu bar is reliable CI.

### What CAN be verified (scripted / semi-scripted)

| Check | How |
|-------|-----|
| Core logic | `swift test` (CuprimCore: utilization, formatting, classifiers) |
| Compiles | `swift build -c debug --arch arm64` (and release if shipping) |
| Packages | `CONFIG=debug LAUNCH=0 ./script/package_app.sh` → `dist/Cuprim.app` |
| Info.plist / version | `plutil` / `PlistBuddy` on packaged app |
| Ad-hoc sign | `codesign -dv dist/Cuprim.app` |
| Open Settings window | After launch: `osascript -e 'tell application "Cuprim" to activate'` then send ⌘, **if** the app accepts it; otherwise open via status menu → **Settings…** (manual) |
| Open About | App menu **About Cuprim** or status menu (manual / light AppleScript activate) |
| Release packaging | `./script/release.sh` (produces DMG + zip; slow; don’t run unless the claim needs it) |

### What is MANUAL (required for UI claims)

- Menu-bar gauge appears and updates
- Status menu **Usage** rows / empty “No providers signed in”
- **Show Cuprim** glass dashboard panel
- Provider tabs, refresh (⌘R), Settings toggles/reorder
- First-launch dashboard with five provider states
- Low-quota alerts (20% / 5%) and Notification Settings recovery
- **Check for Updates…** (Sparkle in release; debug explains it is skipped)
- First-open Gatekeeper behavior for ad-hoc builds
- Menu-bar tooltip remaining percent without a contradictory “Limit reached” suffix

When proving a UI feature, follow the matching file under [`features/`](features/). Capture screenshots manually (⌘⇧4 or Screenshot app) into the evidence path below. State clearly: `manual UI` vs `scripted build`.

### Isolation

Only one menu-bar Cuprim should own the status item. Do not launch a second copy alongside the user’s installed app without quitting yours first. Prefer driving `dist/Cuprim.app` from this checkout.

## Evidence

Put artifacts under:

```
.cursor/skills/verify-cuprim/evidence/<claim-slug>/
```

Suggested files:

- `swift-build.log` — `swift build -c debug --arch arm64` transcript
- `swift-test.log` — `swift test` transcript
- `package.log` — packaging transcript
- `doctor.txt` — uname / sw_vers / codesign / plist snippets
- `ui-*.png` — manual screenshots (dashboard, settings, about, first launch)
- `NOTES.md` — claim, entry point, scripted vs manual, result

Proof standards:

- Exercise the real user path for UI claims (status menu / Settings), not only unit tests
- For logic-only changes in `CuprimCore`, `swift test` + successful package is enough
- Capture action + resulting state (e.g. Settings toggle + menu reflecting order)
- Do not mock provider APIs unless the change is explicitly behind a test double that already exists — this app reads real local credentials
- Evidence survives cleanup

## Cleanup

- Quit only the Cuprim instance **this run** started (AppleScript quit or PID you recorded)
- Never `killall` by name if you cannot tell user vs verify instance apart
- Do not delete `dist/` evidence copies you moved into `evidence/`; you may leave `dist/Cuprim.app` as a cache
- Never delete `evidence/` during teardown
- Do not uninstall `/Applications/Cuprim.app` or clear user preferences/login items

## Feature map

Index: [`features/README.md`](features/README.md)

| Feature | File |
|---------|------|
| Menu-bar status | [`features/menu-bar-status.md`](features/menu-bar-status.md) |
| Dashboard panel | [`features/dashboard-panel.md`](features/dashboard-panel.md) |
| Settings | [`features/settings.md`](features/settings.md) |
| Check for updates | [`features/check-for-updates.md`](features/check-for-updates.md) |
| About | [`features/about.md`](features/about.md) |

Keep the map honest with `/maintain-verification-skill` when UI entry points change.
