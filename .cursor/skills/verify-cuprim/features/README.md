# Cuprim verification map

Maintained source for verifying user-facing Cuprim behavior. Read this index, then the feature file that matches the claim.

## Baseline preconditions

- Host is **Apple Silicon** (`arm64`) and **macOS 26+**
- Work from the repo root; prefer `dist/Cuprim.app` built by this run
- `swift test` passes for CuprimCore claims; package with `CONFIG=debug LAUNCH=0 ./script/package_app.sh` when you need a runnable `.app`
- Launch with `./script/build_and_run.sh` only when a live menu-bar instance is required
- Do not drive a Cuprim you did not start for this verification run when the claim depends on your binary
- Provider sign-in is optional for “empty / not signed in” paths; signed-in providers are required for live quota numbers

## Driving conventions

- Menu-bar and `NSMenu` interactions are **manual** unless a feature file names a specific AppleScript that was proven on this Mac
- Scripted baseline for every run: `swift build`, `swift test`, package app, record logs under `evidence/<claim-slug>/`
- Start from a freshly packaged debug app when proving UI that depends on your change
- Restore preference toggles you flip; do not leave Launch at Login enabled unless that was the claim
- Keep proof artifacts; cleanup only quits the process this run started

## Proof and skip reporting

- UI proof = screenshot of the status menu / panel / window showing Cuprim chrome + the claimed state
- Build proof = log + exit code `0` + `dist/Cuprim.app` exists
- Network features (updates) may fail offline — report the dialog text, not a fake pass
- If a path is unreachable (no Accessibility to the status item), say `manual-only` and attach what you could capture
- Do not mark a feature verified only because a different feature’s screenshot looks fine

## Feature entry contract

Each feature file: H1 + short description, then exactly four H2s — `Sub-features`, `How to get to it (user POV)`, `Driving it with verify-cuprim`, `Gotchas`.

## Features

- [Menu-bar status](./menu-bar-status.md) — gauge, usage menu, refresh, quit
- [Dashboard panel](./dashboard-panel.md) — glass “Show Cuprim” panel
- [Settings](./settings.md) — providers, display, launch at login
- [Share screenshot](./share-screenshot.md) — per-provider share card to pasteboard / apps
- [Check for updates](./check-for-updates.md) — GitHub Releases update check
- [About](./about.md) — About window and version string
