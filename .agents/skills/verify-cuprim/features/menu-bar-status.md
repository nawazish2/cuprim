# Menu-bar status

The menu-bar gauge is the primary entry: click it to toggle the glass dashboard. There is no native usage menu.

## Sub-features

- `status-visible` shows the Cuprim status item in the menu bar after launch
- `click-opens-dashboard` toggles the glass panel from the status item
- `refresh` reloads from the dashboard (⌘R)
- `quit` exits via the dashboard **Quit Cuprim** row (⌘Q)

## How to get to it (user POV)

- Launch Cuprim (`./script/build_and_run.sh` or open `dist/Cuprim.app`)
- Click the gauge / chart status item
- The glass dashboard appears (click again or outside to dismiss)

## Driving it with verify-cuprim

Preconditions:

- Doctor passed on an arm64 macOS 26+ host
- This run’s `dist/Cuprim.app` is running (or just packaged for build-only claims)

- **Build proof.** Run `swift build -c debug --arch arm64` and `CONFIG=debug LAUNCH=0 ./script/package_app.sh`. Exit `0`; app binary exists.
- **Launch.** Run `./script/build_and_run.sh`. Record PID / process path in `doctor.txt`.
- **Status visible (manual).** Confirm the status item appears. Screenshot the menu bar region → `evidence/<slug>/ui-status-item.png`.
- **Open dashboard (manual).** Click the status item. Expect the glass panel (not a native NSMenu). Screenshot → `ui-dashboard.png`.
- **Refresh (manual).** Click the dashboard refresh control. Note result in `NOTES.md`.
- **Quit (manual).** Dashboard footer **Quit Cuprim**. `pgrep` no longer lists this run’s binary.

## Gotchas

- Status items are not reliably scriptable; treat UI steps as manual
- Empty usage is valid when providers are logged out — not an automatic failure
- Do not confuse `/Applications/Cuprim.app` with this checkout’s `dist/` build
- Clicking a usage row opens the dashboard (see dashboard-panel) rather than a separate window
