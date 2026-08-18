# Dashboard panel

Clicking the menu-bar gauge opens the glass dashboard (~300×420).

## Sub-features

- `panel-open` opens the floating dashboard from the status item
- `panel-content` shows provider meters or signed-out / expired / failed states
- `first-launch` shows all five providers with live connection actions
- `panel-hide` dismisses the panel (click away or click the gauge again)

## How to get to it (user POV)

- Click the menu-bar gauge
- Click the gauge again or click away to dismiss
- Settings and Quit live in the dashboard footer

## Driving it with verify-cuprim

- Live instance from this run’s packaged app
- **Open panel (manual).** Click the status item. Panel appears with Cuprim chrome.
- **Inspect (manual).** Confirm All + five provider icons, refresh, footer Settings/Quit. Screenshot → `ui-dashboard.png`.
- **States.** Signed out vs session expired vs offline-with-last-good must not look the same.

## Gotchas

- Clicking the gauge while the panel is open hides it
- First launch opens the panel once
- `CUPRIM_DEMO=1` loads redacted snapshots for captures — never ship personal quota in website assets
