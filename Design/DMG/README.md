# Cuprim DMG background

Drag-to-Applications installer art for the release DMG.

| Spec | Value |
|------|--------|
| Window | 660×400 pt (`create_dmg.sh` bounds `{200, 120, 860, 520}`) |
| Art | 1320×800 PNG (@2x) → `Design/DMG/background.png` |
| Icon positions (pt) | Cuprim.app `(150, 185)` · Applications `(510, 185)` |
| Generator | `script/generate_dmg_background.py` (“Paper Pour”) |

## Visual direction

Quiet **paper/ink** field (`#f4f6f3` / `#181b17`) with brand blue (`#0073eb`) pour-chevrons and a faint cup watermark. Not Raycast (no keyboard photo, neon cyan, pink glow).

Finder draws the “Cuprim.app” / “Applications” labels under icons — they are not baked into the PNG.

## Rebuild

```bash
# Background only
python3 script/generate_dmg_background.py

# Full DMG (needs a packaged .app)
./script/create_dmg.sh dist/Cuprim.app dist/Cuprim-<version>.dmg
# or via release:
./script/release.sh
```
