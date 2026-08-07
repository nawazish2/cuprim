# Settings

Settings is a compact System Settings–style window: provider enable/order, display toggles, launch at login, and about/update links.

## Sub-features

- `settings-open` opens Settings from the status menu or ⌘,
- `providers-toggle-reorder` enables/disables providers and reorders menu/dashboard
- `display-toggles` controls used %, absolute reset times, hide logged-out providers
- `launch-at-login` toggles login item when the signed build supports it

## How to get to it (user POV)

- Status menu → **Settings…**
- With Cuprim active: **⌘,**
- App Settings scene (SwiftUI Settings)

## Driving it with verify-cuprim

Preconditions:

- Live instance from this run
- Note prior preference values before changing them

- **Open (manual).** Status menu → **Settings…** (or activate app and press ⌘,). Window ~380×520 with Providers / Display / General / About groups.
- **Screenshot.** Capture the window → `evidence/<slug>/ui-settings.png`.
- **Provider order (manual, if claimed).** Use arrows to reorder; reopen status menu and confirm order matches.
- **Display toggle (manual, if claimed).** Flip **Show used %**; confirm menu/dashboard copy updates after refresh.
- **Launch at login.** Only exercise if the claim is about login items. Ad-hoc builds may show unavailable / requires approval — that message is acceptable proof of the gated path.
- **Restore.** Put toggles/order back unless the user asked to keep them.

## Gotchas

- Launch at login often needs a Developer ID–signed build; don’t fail ad-hoc debug on “unavailable”
- Don’t leave Launch at Login on after a verify run
- Settings is the SwiftUI Settings scene — avoid inventing a second custom preferences window
