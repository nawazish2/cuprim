# Cuprim — website design

Landing page for **Cuprim**, a free local-only macOS menu-bar AI quota tracker.

**Goals:** one clear first viewport, honest install story, download CTA that hits a real GitHub Release.

**Non-goals (v1):** purchase flow, blog, changelog, waitlist, third-party analytics.

---

## Brand

| Token | Value |
|-------|-------|
| Name | Cuprim |
| Meaning | cup + rim — usage at the menu-bar edge |
| Domain (target) | `cuprim.app` (interim: Vercel preview / `getcuprim.com`) |
| GitHub | `nawazish2/cuprim` |
| License | MIT |

### Visual tokens (from the app)

Pulled from `ShareCardView` accent and `GlassChrome` radii — not an invented purple-AI palette.

| Token | Value | Notes |
|-------|-------|--------|
| `--void` | `#04060A` | Page / mock night sky |
| `--mist` | `#101620` | Soft panels |
| `--ink` | `#F2F6FA` | Primary text |
| `--soft` | `#A0B0C4` | Secondary text |
| `--accent` | `#388CFF` | Share-card blue ≈ `rgb(0.22, 0.55, 1.0)` |
| `--cyan` | `#48C4DC` | Signal highlight (DMG “Quota Stream”) |
| `--hot` | `#B4E6FF` | Accent glow tip |
| `--panel-radius` | `14px` | `GlassChrome.panelCorner` |
| `--card-radius` | `10px` | `GlassChrome.cardCorner` |

**Direction:** quiet dark desktop atmosphere + cyan/blue signal. Avoid purple gradients, cream/serif “AI brochure,” and broadsheet newspaper layouts.

**Typography**

- Display / brand: system UI rounded or `SF Pro Display` / `Inter Display` fallback — medium weight wordmark, not a loud serif.
- Body: `SF Pro Text` / `ui-sans-serif` stack.
- Code / paths in FAQ: `ui-monospace`.

---

## Page architecture

```
Sticky nav → Hero (split headline + CTA + Mac mock) → Features → Trust → FAQ → Footer
```

### Sticky nav

- Left: Cuprim wordmark (icon + name) — brand is the primary signal.
- Right: GitHub (text link) · **Download for Mac** (primary button).
- Stays thin; no mega-menu.

### Hero (first viewport)

One composition — not a dashboard.

| Element | Rule |
|---------|------|
| Brand | Cuprim wordmark at hero scale (not only in nav) |
| Headline | One split line — see `COPY.md` |
| Support | One short sentence |
| CTA | Download for Mac → `…/releases/latest` |
| Visual | Full-bleed Mac desktop mock (menu bar + Cuprim status + open panel) — edge-to-edge plane, not an inset card collage |
| Avoid | Stats strips, schedule chips, floating badges on the mock |

### Features (vertical scroll)

Three beats, one job each:

1. **Menu bar gauge** — glance remaining quota without leaving focus.
2. **Four providers** — Claude, Codex, Cursor, Grok in one panel.
3. **Share snapshot** — dark share card for social / Slack.

Each: one headline + one sentence + optional small diagram or cropped screenshot. No card grid in the hero sense; simple stacked sections.

### Trust

Three pillars (no cards unless interaction requires a container):

1. **Local only** — credentials never leave your Mac via us.
2. **No telemetry** — we don’t run analytics on the app or this site.
3. **Open source** — MIT on GitHub; inspect the code.

### FAQ

Honest Gatekeeper copy (ad-hoc signing, not notarized). Providers, privacy, requirements. See `COPY.md`.

### Footer

Download CTA again · GitHub · MIT · author link. Minimal.

---

## Motion (2–3 intentional)

1. Nav: subtle backdrop blur / border fade on scroll.
2. Hero: soft fade-up of headline + mock (once).
3. Features: light opacity/translate as each section enters (respect `prefers-reduced-motion`).

No perpetual glow loops or emoji confetti.

---

## Responsive

Product is Mac-only; traffic still arrives on phones.

- Phone: brand + headline + CTA first; Mac mock scales down or stacks under copy.
- Tablet: split layout compresses; mock remains readable.
- Never hide Download; never claim iOS/Windows.

---

## SEO / social

- Title / description from `COPY.md`.
- Static `website/public/og.png` (1200×630) — no `next/og` on static export.
- Favicon from app icon export.

---

## Download CTA contract

`https://github.com/nawazish2/cuprim/releases/latest`

Must resolve to a Cuprim-branded DMG/zip before launch messaging goes live.

---

## Out of scope visuals

- Fake App Store badges
- “Notarized by Apple” claims
- Third-party tracking pixels
- Purchase / Polar / waitlist UI
