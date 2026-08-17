# Dashboard panel

“Show Cuprim” opens the glass dashboard panel with provider cards/tabs for detailed quota metrics.

## Sub-features

- `panel-open` opens the floating dashboard from the status item
- `panel-content` shows provider metrics (or signed-out / error states) for enabled providers
- `panel-hide` dismisses the panel (click away / reopen menu closes panel per app behavior)

## How to get to it (user POV)

- Click the menu-bar gauge
- Click the gauge again or click away to dismiss

## Driving it with verify-cuprim

Preconditions:

- Live instance from this run’s packaged app
- Prefer at least one provider enabled in Settings (signed-in optional for empty/error UI)

- **Open panel (manual).** Click the status item. Panel appears with Cuprim chrome.
- **Inspect (manual).** Confirm provider tabs/cards match enabled providers. Screenshot → `evidence/<slug>/ui-dashboard.png`.
- **Toggle (manual).** Click the gauge again. Panel hides.
- **Build adjunct.** If the change was layout-only in `Views/`, also keep `swift build` + package logs; UI screenshot remains required for visual claims.

## Gotchas

- Clicking the gauge while the panel is open hides it
- Without signed-in providers, “ok” metrics will not appear; assert the empty/error UI instead of inventing quotas
- Panel is not a normal document window; don’t look for it in the Dock as a separate app switcher entry beyond Cuprim itself
