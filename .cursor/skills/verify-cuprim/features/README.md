# Cuprim verification map

Maintained source for verifying user-facing Cuprim behavior. Read this index, then the feature file that matches the claim.

## Baseline preconditions

- Host is **Apple Silicon** (`arm64`) and **macOS 26+**
- Work from the repo root; prefer `dist/Cuprim.app` built by this run
- `swift test` passes for CuprimCore / CuprimProviders claims; package with `CONFIG=debug LAUNCH=0 ./script/package_app.sh` when you need a runnable `.app`
- Launch with `./script/build_and_run.sh` only when a live menu-bar instance is required
- Do not drive a Cuprim you did not start for this verification run when the claim depends on your binary
- Provider sign-in is optional for “empty / not signed in” paths; signed-in providers are required for live quota numbers

## Driving conventions

- Menu-bar extras are **manual** unless a feature file names a specific AppleScript that was proven on this Mac
- Scripted baseline for every run: `swift build`, `swift test`, package app, record logs under `evidence/<claim-slug>/`
- Start from a freshly packaged debug app when proving UI that depends on your change
- Restore preference toggles you flip; do not leave Launch at Login enabled unless that was the claim
- Keep proof artifacts; cleanup only quits the process this run started

## Proof and skip reporting

- UI proof = screenshot of the panel / window showing Cuprim chrome + the claimed state
- Build proof = log + exit code `0` + `dist/Cuprim.app` exists, Sparkle.framework present, `LSUIElement` true
- Network features (updates) may fail offline — report the dialog text, not a fake pass
- If a path is unreachable (no Accessibility to the status item), say `manual-only` and attach what you could capture

## Features

- [Menu-bar status](./menu-bar-status.md) — gauge, click-opens-dashboard, severity variants
- [Dashboard panel](./dashboard-panel.md) — glass panel, first launch, provider states
- [Settings](./settings.md) — providers, display, refresh and alerts, about
- [Check for updates](./check-for-updates.md) — Sparkle in release builds
- [About](./about.md) — About window, Nawazish credit, local-only line
