# Cuprim delight pass (app + website)

Make Cuprim feel calmer, faster, and more finished — the kind of menu-bar tool people keep after the first hour. **Keep the product contract:** left-click opens the slim native menu; glass dashboard stays behind **Show Cuprim** / a provider row; ~300×420; no new menu items; no Share Screenshot; no paywall, accounts, or telemetry.

## What customers feel today

The bones are good (native NSMenu + Liquid Glass panel). The love is leaking at the edges:

- **Dashboard appears and vanishes with no motion.** `PanelController` `orderFront` / `orderOut` is instant. Premium menu-bar apps spring from the status item.
- **First hour is a dead end.** Empty dashboard is two lines of text and no button. Empty menu is “No providers signed in.” New users do not know what to do next.
- **Refresh is technically correct, emotionally flat.** Global spinner + rotating gauge. Overview “average % used” mixes unrelated windows (a 5% weekly + 90% session reads as ~47%). Settings **Absolute reset times** is wired in prefs but **not used** — `DashboardView` hardcodes `absoluteResets: false`, and `MetricRowView` never reads the flag.
- **Settings comment lies.** Prefs say “Drag to reorder with the cursor”; the UI is up/down chevrons.
- **Website feature grid is a 10-cell wall** (“What you get”) that fights the site’s own “sparse over card grids” rule. Hero MacBook still uses static captures (`cuprim-menu.webp`, `cuprim-dashboard.webp`) that will drift the moment the app polish lands.

## Non-goals

- Click-opens-dashboard
- Full visual redesign, colorful menu chips, Share Screenshot, About in the status menu
- Version bump / GitHub Release / notarization
- Sparkle rewrite, new providers, website analytics
- `macos-settings-ui` sidebar Settings rewrite (too big for this pass)

## Shared principles (app + site)

1. **Glance, then detail.** Menu = 1-line status. Panel = meters. Site = one honest product proof.
2. **Native, not glassmorphic-for-its-own-sake.** App stays HIG / Liquid Glass. Site stays paper + frost (Purge/Alcove family).
3. **Motion is short and springy.** Respect Reduce Motion. No looping decoration.
4. **Every empty / error / first-open state has a next step.**
5. **Ship app polish first, then recapture the site** so marketing matches the build.

## App

1. Panel open/close fade + slight scale from the status item. Reduce Motion = instant.
2. Empty dashboard: “Nothing to show yet” + sign-in line + **Open Settings…**. Loading: skeleton cards. Menu empty: “No providers signed in — open Settings…”
3. Refresh check-then-back. Overview shows tightest remaining % (not average). Honor **Absolute reset times**. Stale caption: “May be outdated.”
4. Settings: drag to reorder providers; footer matches the control.
5. Notification: “Claude · 15% left on Session” + reset if known.

## Website (after app)

6. Recapture `cuprim-menu.webp` and `cuprim-dashboard.webp` from the polished app.
7. Feature grid: 6 cells (menu bar, glance + panel, four providers, local only, no telemetry, free MIT).
8. Quiet Gatekeeper line under the hero download row.
9. Keep paper tokens / cup mark / frost nav. No new sections or analytics.

## Come back later

```bash
cd ~/Developer/tokenbar
git fetch origin
git checkout delight-pass
```

Resume with “continue the delight pass” or open this file.

Do not bump `script/package_app.sh` version unless asked.
