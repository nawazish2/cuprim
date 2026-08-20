# Design assets — Cuprim website

| Asset | Path | Size |
|-------|------|------|
| Favicon / icons | `website/public/favicon.png`, `icon-192.png`, `icon-512.png` | 32×32, 192×192, 512×512 |
| OG image | `website/public/og.png` | 1200×630 |
| Hero MacBook frame | `website/public/macbook-frame.webp` (Apple-provided MacBook Air M5 13-inch silver bezel) | 1700×1120, transparent screen cutout at `left:12.35% top:12.86% width:75.29% height:74.2%` |
| Hero screen layers | `website/public/macos-wallpaper.webp`, `cuprim-gauge.webp`, `cuprim-dashboard.webp` | wallpaper 1586×992 · gauge 160×160 · dashboard panel 600×840 |
| Hero static fallback | `website/public/macbook-demo-poster.webp` | 1700×1260 |
| Glance section visual | `website/public/cuprim-glance.webp` | 1280×720 |
| Providers section visual | `website/public/cuprim-providers.webp` | 600×500 |
| Cup mark | `CupLogo.vue`, source `Design/AppIcon/cup-mark.svg` | — |

`website/public/macos-wallpaper.avif` is currently unreferenced (no `<picture>` element uses it) — leave it or wire it up, don't just delete it without checking.

Stack: Nuxt 4 + Tailwind static → Cloudflare Workers (`https://cuprim.knawazish153.workers.dev`).

## Recapturing product screenshots

The dashboard, gauge, and every composite built from them (poster, glance,
providers, OG) come from a real running build in demo mode — never crop a
screenshot with live personal quota into `website/public/`.

```bash
# 1. Build a debug app (LAUNCH=0 so it doesn't auto-open with the wrong env)
CONFIG=debug LAUNCH=0 ./script/package_app.sh

# 2. Launch with the env var forwarded — plain `open` does NOT forward
#    exported shell vars, so CUPRIM_DEMO=1 ./script/build_and_run.sh
#    silently launches with real credentials instead of demo data.
open --env CUPRIM_DEMO=1 dist/Cuprim.app
```

Before capturing, confirm the panel shows the frozen demo values from
`Sources/CuprimCore/DemoSnapshots.swift` (Claude Pro 42%/18%, Codex Plus
61%/33%, Cursor Pro 27%/9%/18%, Grok SuperGrok 54%) — if you see anything
else, it's real data, quit and relaunch. All four providers must be enabled
in your real Settings first, or they won't appear even in demo mode
(provider visibility reads real `PreferencesStore`).

Crop the panel to its exact bounds rather than eyeballing a screen region —
query them via Accessibility so there's zero background bleed at the edges:

```bash
osascript -e 'tell application "System Events" to tell process "Cuprim" to return {position of window 1, size of window 1}'
```

Multiply by the display's backing scale factor (compare a full
`screencapture` pixel size against the logical screen resolution from
`osascript -e 'tell application "Finder" to get bounds of window of desktop'`)
to convert those points to the pixel rect to crop from a `screencapture -x`
capture.
