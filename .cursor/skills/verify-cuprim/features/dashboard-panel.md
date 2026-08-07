# Dashboard panel

“Show Cuprim” opens the glass dashboard panel with provider cards/tabs for detailed quota metrics.

## Sub-features

- `panel-open` opens the floating dashboard from the status menu or a usage row
- `panel-content` shows provider metrics (or signed-out / error states) for enabled providers
- `panel-hide` dismisses the panel (click away / reopen menu closes panel per app behavior)

## How to get to it (user POV)

- Status menu → **Show Cuprim**
- Status menu → click a provider usage row (also shows dashboard)

## Driving it with verify-cuprim

Preconditions:

- Live instance from this run’s packaged app
- Prefer at least one provider enabled in Settings (signed-in optional for empty/error UI)

- **Open panel (manual).** Status menu → **Show Cuprim**. Panel appears with Cuprim chrome.
- **Inspect (manual).** Confirm provider tabs/cards match enabled providers. Screenshot → `evidence/<slug>/ui-dashboard.png`.
- **From usage row (manual).** Reopen menu, click a provider row. Panel shows that provider context.
- **Build adjunct.** If the change was layout-only in `Views/`, also keep `swift build` + package logs; UI screenshot remains required for visual claims.

## Gotchas

- Opening the status menu hides an already-visible panel (`menuWillOpen`) — expected
- Without signed-in providers, “ok” metrics will not appear; assert the empty/error UI instead of inventing quotas
- Panel is not a normal document window; don’t look for it in the Dock as a separate app switcher entry beyond Cuprim itself
