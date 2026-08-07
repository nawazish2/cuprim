# Cuprim — visual references

Inspiration for layout and tone — not clones. Cuprim keeps its own cyan/blue signal palette and honest utility copy.

---

## Primary layout references

| Product | What to steal | What to ignore |
|---------|---------------|----------------|
| [Alcove](https://tryalcove.com/) | Sticky minimal nav, confident brand-first hero, calm dark atmosphere | Feature overload below the fold |
| [Klack](https://tryklack.com/) | Single-job product page, playful but sparse, strong first viewport | Novelty gimmicks that don’t fit a quota tool |
| [Purge](https://purge.macapp.supply/) / macapp.supply family | Split headline + Mac mock, clear Download CTA, short trust/FAQ | Cookie-cutter purple SaaS gradients |

## Secondary

| Reference | Use |
|-----------|-----|
| Apple HIG menu bar / status items | How the Mac mock should feel (system chrome, not a fake phone UI) |
| Cuprim DMG “Quota Stream” art | Atmosphere continuity (night void + cyan signal curve) |
| Cuprim share card (`ShareCardView`) | Accent blue `#388CFF`, dark card language for screenshots |

---

## Composition rules (from plan + DESIGN.md)

1. First viewport = one composition: brand, one headline, one sentence, one CTA group, one dominant Mac mock.
2. Brand must survive the “remove the nav” test.
3. No inset hero media cards / floating badge stickers on the mock.
4. Cards only when they hold interaction; default is open sections.
5. FAQ must include Gatekeeper ad-hoc path — never “notarized” unless true.

---

## Asset checklist

| Asset | Path / note | Status |
|-------|-------------|--------|
| App icon Default 1024 | `Design/AppIcon/Exports/Cuprim-Default-1024.png` | Exists |
| App icon Dark / About / Tinted | `Design/AppIcon/Exports/Cuprim-*.png` | Exists |
| DMG background | `Design/DMG/background.png` (regenerate via `script/generate_dmg_background.py`) | Exists — regenerate after rename |
| Hero Mac mock | `Design/Website/hero-mac-mock.png` or CSS mock in site | Build in website |
| Feature crops (optional) | Menu bar, panel, share card | Prefer CSS mock + icon for v1 |
| OG image 1200×630 | `website/public/og.png` | Generate with site |
| Favicon | `website/public/favicon.png` from app icon | Generate with site |

### Screenshots still useful later

1. Real menu bar with Cuprim gauge (desktop screenshot).
2. Open dashboard panel over wallpaper.
3. Share card pasteboard preview.
4. Settings / About windows (secondary).

Until those land, the site ships a faithful CSS/SVG Mac mock branded Cuprim.
