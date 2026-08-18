# Settings

Settings is an AppKit window (not a SwiftUI Settings scene): Providers, Display, Refresh and alerts, About and updates.

## Sub-features

- `settings-open` opens Settings from the dashboard footer or ⌘,
- `providers-toggle-reorder` enables/disables providers and shows connection state
- `display-toggles` controls used %, absolute reset times, hide signed-out providers
- `alerts` low-quota alerts with notification permission recovery
- `launch-at-login` toggles login item when the signed build supports it

## How to get to it (user POV)

- Dashboard footer → **Settings…**
- With the panel key: **⌘,**

## Driving it with verify-cuprim

- **Open (manual).** Dashboard footer Settings. Native grouped window.
- Screenshot → `ui-settings.png`
- Restore toggles; do not leave Launch at Login on

## Gotchas

- Launch at login often needs a Developer ID–signed build; ad-hoc may show unavailable
- Do not use the SwiftUI Settings scene — it was removed
- Opening Settings must go through `SettingsOpener` after menu/panel tracking ends
