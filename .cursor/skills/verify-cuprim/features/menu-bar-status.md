# Menu-bar status

The menu-bar gauge is the primary surface: click it for a native usage menu (provider rows, refresh, settings entry, share, about, updates, quit).

## Sub-features

- `status-visible` shows the Cuprim status item in the menu bar after launch
- `usage-rows` lists enabled providers with plan/subtitle or empty/loading copy
- `refresh` reloads provider snapshots from the menu (⌘R while menu targets allow)
- `quit` exits via **Quit Cuprim** (⌘Q)

## How to get to it (user POV)

- Launch Cuprim (`./script/build_and_run.sh` or open `dist/Cuprim.app`)
- Click the gauge / chart status item
- Choose **Refresh**, a provider row, or **Quit Cuprim**

## Driving it with verify-cuprim

Preconditions:

- Doctor passed on an arm64 macOS 26+ host
- This run’s `dist/Cuprim.app` is running (or just packaged for build-only claims)

- **Build proof.** Run `swift build -c debug --arch arm64` and `CONFIG=debug LAUNCH=0 ./script/package_app.sh`. Exit `0`; app binary exists.
- **Launch.** Run `./script/build_and_run.sh`. Record PID / process path in `doctor.txt`.
- **Status visible (manual).** Confirm the status item appears. Screenshot the menu bar region → `evidence/<slug>/ui-status-item.png`.
- **Open menu (manual).** Click the status item. Expect **Usage** header and either provider rows or “No providers signed in” / “Loading…”. Screenshot → `ui-status-menu.png`.
- **Refresh (manual).** Choose **Refresh**. Menu may show “Refreshing…” then updated subtitles. Note result in `NOTES.md`.
- **Quit (manual).** Choose **Quit Cuprim**. `pgrep` no longer lists this run’s binary.

## Gotchas

- Status items are not reliably scriptable; treat UI steps as manual
- Empty usage is valid when providers are logged out — not an automatic failure
- Do not confuse `/Applications/Cuprim.app` with this checkout’s `dist/` build
- Clicking a usage row opens the dashboard (see dashboard-panel) rather than a separate window
