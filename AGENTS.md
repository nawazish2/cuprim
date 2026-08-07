# TokenBar — agent notes

## What this is

**TokenBar** is a free macOS **menu-bar** app that shows quota usage for **Claude**, **Codex**, **Cursor**, and **Grok**.

- Local only: no accounts with us, no telemetry, no cloud sync, no backend
- Credentials stay on the machine; TokenBar only talks to each provider’s own usage API
- Swift Package (`Package.swift`) + AppKit/SwiftUI; not an Xcode project by default

## Requirements

- **Apple Silicon** (arm64) only
- **macOS 26+** (Liquid Glass)
- Providers the user cares about already signed in locally (Claude Code/Desktop, Codex CLI `~/.codex/auth.json`, Cursor, Grok Build / `grok login`)

Cloud/Linux agents **cannot** compile or run the app. Treat build/package/UI verification as **manual on an Apple Silicon Mac**, or skip with that precondition stated.

## Build / run / package / release

All scripts live under `script/` (singular).

| Goal | Command |
|------|---------|
| Dev: package debug `.app` and launch | `./script/build_and_run.sh` |
| Package only (debug) | `CONFIG=debug LAUNCH=0 ./script/package_app.sh` |
| Package only (release) | `CONFIG=release LAUNCH=0 ./script/package_app.sh` |
| Unit tests (TokenBarCore) | `swift test` |
| Release artifacts (`.app` + DMG + zip) | `./script/release.sh` |
| Developer ID sign (optional) | `CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./script/release.sh` |
| DMG only (given an `.app`) | `./script/create_dmg.sh dist/TokenBar.app dist/TokenBar-0.1.3.dmg` |

Outputs land in `dist/` (gitignored). Default signing is **ad-hoc** (`CODESIGN_IDENTITY=-`).

**Version** is embedded in `script/package_app.sh` (`CFBundleShortVersionString` / `CFBundleVersion`). Do **not** bump unless asked. Notarization notes: `docs/NOTARIZATION.md`.

### Gatekeeper (ad-hoc builds)

First open may be blocked. User workarounds: right-click → Open, or `xattr -cr /Applications/TokenBar.app` (or the `dist/` path).

## Source layout

```
Package.swift                 # SPM: TokenBarCore + TokenBar executable, macOS 26+
Sources/TokenBarCore/         # Pure models / formatting / utilization (unit-tested)
Sources/TokenBar/
  App/                        # Lifecycle, status item, panel, settings/about windows
  Providers/{Claude,Codex,Cursor,Grok}/
  Stores/                     # Usage, preferences, dashboard UI state
  Services/                   # HTTP, snapshot cache
  Views/                      # Dashboard, settings, share card, about, …
  Support/                    # Icons, updater, share, platform checks, …
  Resources/                  # Icons (copied into .app by package_app.sh; excluded from SPM target)
Tests/TokenBarTests/          # Shipped-logic tests against TokenBarCore
script/                       # build_and_run, package_app, release, create_dmg, icon helpers
Design/                       # App icon layers, DMG background
docs/                         # Notarization / distribution
```

## Agent do / don’t

**Do**

- Prefer `/poteto-mode` rigor for non-trivial work
- Match existing Swift style; keep changes local and readable
- Verify by building/packaging on macOS when possible (`./script/build_and_run.sh` or `swift test` + `./script/package_app.sh`)
- Use project skill `.cursor/skills/verify-tokenbar/` for structured proof
- Prefer pushing to `main` for solo work when that is the agreed workflow; otherwise use a short-lived branch + PR

**Don’t**

- Commit unless the user asked (or the cloud/PR workflow explicitly requires it for this run)
- Force-push
- Reopen Polar / paywall / monetization work
- Invent cloud sync, accounts, telemetry, or a TokenBar backend
- Bump version or cut a GitHub Release unless asked
- Change product behavior when the task is docs/skills/tooling only
- Kill unrelated processes when cleaning up a verification run

## Privacy stance (product)

Keep the product local-only. Do not add analytics SDKs, remote config, or “sync to our servers” features.
