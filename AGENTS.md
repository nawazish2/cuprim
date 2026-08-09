# Cuprim — agent notes

## What this is

**Cuprim** is a free macOS **menu-bar** app that shows quota usage for **Claude**, **Codex**, **Cursor**, and **Grok**.

- Local only: no accounts with us, no telemetry, no cloud sync, no backend
- Credentials stay on the machine; Cuprim only talks to each provider’s own usage API
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
| Unit tests (CuprimCore) | `swift test` |
| Release artifacts (`.app` + DMG + zip) | `./script/release.sh` |
| Developer ID sign (optional) | `CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" ./script/release.sh` |
| DMG only (given an `.app`) | `./script/create_dmg.sh dist/Cuprim.app dist/Cuprim-0.1.3.dmg` |

Outputs land in `dist/` (gitignored). Default signing is **ad-hoc** (`CODESIGN_IDENTITY=-`).

**Version** is embedded in `script/package_app.sh` (`CFBundleShortVersionString` / `CFBundleVersion`). Do **not** bump unless asked. Notarization notes: `docs/NOTARIZATION.md`.

### Gatekeeper (ad-hoc builds)

First open may be blocked. User workarounds: right-click → Open, or `xattr -cr /Applications/Cuprim.app` (or the `dist/` path).

## Source layout

```
Package.swift                 # SPM: CuprimCore + Cuprim executable, macOS 26+
Sources/CuprimCore/         # Pure models / formatting / utilization (unit-tested)
Sources/Cuprim/
  App/                        # Lifecycle, status item, panel, settings/about windows
  Providers/{Claude,Codex,Cursor,Grok}/
  Stores/                     # Usage, preferences, dashboard UI state
  Services/                   # HTTP, snapshot cache
  Views/                      # Dashboard, settings, share card, about, …
  Support/                    # Icons, updater, share, platform checks, …
  Resources/                  # Icons (copied into .app by package_app.sh; excluded from SPM target)
Tests/CuprimTests/          # Shipped-logic tests against CuprimCore
script/                       # build_and_run, package_app, release, create_dmg, icon helpers
Design/                       # App icon layers, DMG background
docs/                         # Notarization / distribution
```

## Agent do / don’t

**Do**

- Prefer `/poteto-mode` rigor for non-trivial work
- Match existing Swift style; keep changes local and readable
- Verify by building/packaging on macOS when possible (`./script/build_and_run.sh` or `swift test` + `./script/package_app.sh`)
- Use project skill `.cursor/skills/verify-cuprim/` for structured proof
- Prefer pushing to `main` for solo work when that is the agreed workflow; otherwise use a short-lived branch + PR

**Don’t**

- Commit unless the user asked (or the cloud/PR workflow explicitly requires it for this run)
- Force-push
- Reopen Polar / paywall / monetization work
- Invent cloud sync, accounts, telemetry, or a Cuprim backend
- Bump version or cut a GitHub Release unless asked
- Change product behavior when the task is docs/skills/tooling only
- Kill unrelated processes when cleaning up a verification run

## Privacy stance (product)

Keep the product local-only. Do not add analytics SDKs, remote config, or “sync to our servers” features.

## Learned User Preferences

- Prefers free and open source; do not reopen Polar, paywall, or monetization work
- For this solo repo, prefer pushing to `main` over branch-and-PR workflows unless asked otherwise
- Prefers compact, premium, native macOS UI (Liquid Glass / HIG, glanceable and readable) over custom web-dashboard glassmorphism; rejects heavy or overworked icon treatments and often prefers earlier simpler icon versions when iterating
- Status menu should be monochrome and compact (native NSMenu, system greys only—no colorful status chips/dots); use “Limit Reached” when exhausted; keep actions slim (e.g. Show Cuprim / Refresh / Settings / Quit—no Share Screenshot or About in the status menu)
- About and shipping surfaces should credit the author (Created by Nawazish); About belongs in Settings (or the app menu), not the slim status menu
- README and product copy should stay short and local-only focused (private, low RAM); strip unnecessary detail
- Share screenshots/cards should show only the selected provider, not every provider’s usage; do not re-add Share Screenshot to Settings or the status menu without being asked
- Check for Updates should install automatically when an update exists and clearly say when already on the latest
- Prefers reviewing the app or site locally before cloud/remote work
- Marketing site visual direction: mac-utility landings like Purge/Alcove/Klack; light paper + SF hierarchy; sparse sections over card grids; hero led by product mock (monochrome gauge menu, optional glass dashboard); unique cup mark, not Raycast-style
- Do not push the marketing website when releasing the macOS app unless explicitly asked
- Menu bar should stay a quick status overview; detailed usage and analysis belong in the dashboard—do not duplicate detail; prefers dashboard panel size around 300×420; menu-bar glyph should be the native gauge (cup mark stays for app icon/brand)

## Learned Workspace Facts

- Product renamed from TokenBar to Cuprim (name collision in the same niche); GitHub remote/product name is Cuprim
- Marketing site is a Nuxt + Tailwind app under `website/`; design/copy notes live under `docs/website/`
- App icon and menu bar assets live under `Design/AppIcon`, `Design/MenuBar`, and `Sources/Cuprim/Resources/`; DMG/installer background should stay in sync with the current icon
- Menu bar status glyph is the native monochrome gauge (template, high quality at small sizes); cup-with-ring is the app icon / brand mark, not the default status item
- Opening Settings from the status menu must use a dedicated `NSWindow` deferred until after menu tracking ends; `showSettingsWindow` is unreliable and windows opened during menu tracking often never appear
- Dashboard popover preferred content size is about 300×420 (wider denser sizes tend to get rejected)
- Version strings live in `script/package_app.sh`; do not bump version or cut a GitHub Release unless asked
- Apple Silicon + macOS 26+ only; cloud/Linux agents cannot compile or run the `.app`
