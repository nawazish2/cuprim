#!/usr/bin/env python3
"""
Cuprim DMG art — “Quota Stream”

A luminous usage curve that flows from the app into Applications.
Finder window: 660×400pt · art @2x (1320×800).
Icon centers (pt): Cuprim.app (150, 185) · Applications (510, 185)
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 660 * 2, 400 * 2

# Quiet night sky + signal cyan/blue (Cuprim, not purple-AI)
VOID = (4, 6, 10)
MIST = (16, 22, 32)
CYAN = (72, 196, 220)
BLUE = (56, 140, 255)
HOT = (180, 230, 255)
INK = (242, 246, 250)
SOFT = (160, 176, 196)

ICON_L = (150 * 2, 185 * 2)
ICON_R = (510 * 2, 185 * 2)


def load_font(size: int) -> ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/SFCompact.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ):
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def bezier(p0, p1, p2, p3, t: float):
    u = 1 - t
    x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
    y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
    return x, y


def bezier_tangent(p0, p1, p2, p3, t: float):
    u = 1 - t
    dx = (
        3 * u**2 * (p1[0] - p0[0])
        + 6 * u * t * (p2[0] - p1[0])
        + 3 * t**2 * (p3[0] - p2[0])
    )
    dy = (
        3 * u**2 * (p1[1] - p0[1])
        + 6 * u * t * (p2[1] - p1[1])
        + 3 * t**2 * (p3[1] - p2[1])
    )
    return dx, dy


def stream_control_points():
    """Graceful S-curve between the two icon docks."""
    lx, ly = ICON_L
    rx, ry = ICON_R
    p0 = (lx + 100, ly)
    p3 = (rx - 100, ry)
    p1 = (lerp(p0[0], p3[0], 0.35), ly - 95)
    p2 = (lerp(p0[0], p3[0], 0.65), ry + 85)
    return p0, p1, p2, p3


def paint_sky() -> Image.Image:
    img = Image.new("RGB", (W, H), VOID)
    px = img.load()
    assert px is not None
    # Soft vertical wash + twin aurora blooms under icon docks
    blooms = [
        (ICON_L[0], ICON_L[1], 0.55, BLUE),
        (ICON_R[0], ICON_R[1], 0.45, CYAN),
        (W // 2, int(H * 0.55), 0.35, BLUE),
    ]
    for y in range(H):
        vt = y / (H - 1)
        base_r = int(lerp(VOID[0], MIST[0], vt * 0.7))
        base_g = int(lerp(VOID[1], MIST[1], vt * 0.7))
        base_b = int(lerp(VOID[2], MIST[2], vt * 0.7))
        for x in range(W):
            r, g, b = base_r, base_g, base_b
            # Edge vignette
            edge = min(x, W - 1 - x, y, H - 1 - y) / 160.0
            edge = max(0.0, min(1.0, edge))
            k = 0.78 + 0.22 * edge
            r, g, b = int(r * k), int(g * k), int(b * k)
            for bx, by, strength, col in blooms:
                dx = (x - bx) / 280
                dy = (y - by) / 200
                d = math.sqrt(dx * dx + dy * dy)
                w = max(0.0, 1.0 - d) ** 2 * strength
                r = min(255, int(r + col[0] * w * 0.22))
                g = min(255, int(g + col[1] * w * 0.22))
                b = min(255, int(b + col[2] * w * 0.28))
            px[x, y] = (r, g, b)
    return img


def add_film_grain(img: Image.Image) -> Image.Image:
    out = img.copy()
    px = out.load()
    assert px is not None
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            n = ((x * 91 + y * 157) % 13) - 6
            if abs(n) < 3:
                continue
            r, g, b = px[x, y]
            px[x, y] = (
                max(0, min(255, r + n)),
                max(0, min(255, g + n)),
                max(0, min(255, b + n)),
            )
    return out.filter(ImageFilter.GaussianBlur(0.3))


def draw_starfield(layer: Image.Image, rng: random.Random) -> None:
    d = ImageDraw.Draw(layer)
    for _ in range(55):
        x = rng.randint(20, W - 20)
        y = rng.randint(20, H - 20)
        # Keep stars out of the icon/stream corridor a bit
        if abs(y - ICON_L[1]) < 90 and 220 < x < 1100:
            continue
        r = rng.choice([1, 1, 1, 2, 2, 3])
        a = rng.randint(25, 90)
        col = HOT if rng.random() > 0.7 else CYAN
        d.ellipse([x - r, y - r, x + r, y + r], fill=(*col, a))


def draw_menu_bar_wink(layer: Image.Image) -> None:
    """Whisper of a menu bar — where Cuprim actually lives."""
    d = ImageDraw.Draw(layer)
    y = 26
    # Ultra-thin menubar strip
    d.rounded_rectangle(
        [W // 2 - 110, y, W // 2 + 110, y + 8],
        radius=4,
        fill=(255, 255, 255, 12),
    )
    # Fake status items: wifi · clock · Cuprim glow
    for ox, a in ((-70, 50), (-42, 50), (70, 50)):
        d.ellipse([W // 2 + ox - 2, y + 2, W // 2 + ox + 2, y + 6], fill=(255, 255, 255, a))
    # Cuprim status item — the bright one
    d.ellipse([W // 2 - 5, y, W // 2 + 5, y + 8], fill=(*BLUE, 200))
    d.ellipse([W // 2 - 2, y + 2, W // 2 + 2, y + 6], fill=(*HOT, 240))


def draw_glass_docks(layer: Image.Image) -> None:
    """Frosted landing pads under Finder icons."""
    for cx, cy, tint in ((ICON_L[0], ICON_L[1], BLUE), (ICON_R[0], ICON_R[1], CYAN)):
        pad = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(pad)
        # Outer bloom
        d.ellipse([cx - 130, cy - 70, cx + 130, cy + 150], fill=(*tint, 40))
        pad = pad.filter(ImageFilter.GaussianBlur(28))
        layer.alpha_composite(pad)

        glass = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glass)
        # Soft disc
        gd.ellipse([cx - 88, cy + 40, cx + 88, cy + 100], fill=(255, 255, 255, 22))
        # Rim highlight
        gd.arc([cx - 88, cy + 40, cx + 88, cy + 100], 200, 340, fill=(255, 255, 255, 55), width=2)
        layer.alpha_composite(glass.filter(ImageFilter.GaussianBlur(2)))


def draw_quota_stream(layer: Image.Image, rng: random.Random) -> None:
    p0, p1, p2, p3 = stream_control_points()
    samples = [bezier(p0, p1, p2, p3, t / 80) for t in range(81)]

    # Wide soft ribbon glow
    ribbon = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ribbon)
    for i, (x, y) in enumerate(samples):
        t = i / 80
        r = int(lerp(28, 18, t))
        a = int(lerp(50, 90, t))
        col = (
            int(lerp(BLUE[0], CYAN[0], t)),
            int(lerp(BLUE[1], CYAN[1], t)),
            int(lerp(BLUE[2], CYAN[2], t)),
            a,
        )
        rd.ellipse([x - r, y - r, x + r, y + r], fill=col)
    layer.alpha_composite(ribbon.filter(ImageFilter.GaussianBlur(16)))

    # Crisp luminous core stroke
    core = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(core)
    for width, alpha in ((14, 40), (7, 110), (3, 230)):
        pts = [(x, y) for x, y in samples]
        cd.line(pts, fill=(*HOT, alpha), width=width)
    layer.alpha_composite(core.filter(ImageFilter.GaussianBlur(0.6)))

    # Floating “token” beads along the stream
    beads = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(beads)
    for t in (0.12, 0.28, 0.44, 0.58, 0.72, 0.86):
        x, y = bezier(p0, p1, p2, p3, t)
        size = 5 + int(3 * math.sin(t * math.pi))
        # Outer glow
        bd.ellipse([x - size - 4, y - size - 4, x + size + 4, y + size + 4], fill=(*CYAN, 50))
        bd.ellipse([x - size, y - size, x + size, y + size], fill=(*HOT, 230))
        # Tiny specular
        bd.ellipse([x - size // 2, y - size // 2 - 1, x, y], fill=(255, 255, 255, 180))
    layer.alpha_composite(beads.filter(ImageFilter.GaussianBlur(0.4)))

    # Mini glass quota meters — each a different “provider” vibe
    meters = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    md = ImageDraw.Draw(meters)
    accents = (
        (0.22, 0.72, -48, (64, 156, 255)),   # blue
        (0.52, 0.45, 52, (72, 196, 180)),    # teal
        (0.78, 0.88, -40, (120, 170, 255)),  # soft indigo-blue
    )
    for t, pct, offset, accent in accents:
        x, y = bezier(p0, p1, p2, p3, t)
        y += offset
        rad = 24
        # Glass disc
        md.ellipse([x - rad, y - rad, x + rad, y + rad], fill=(10, 14, 22, 170))
        md.ellipse(
            [x - rad, y - rad, x + rad, y + rad],
            outline=(255, 255, 255, 35),
            width=2,
        )
        bbox = [x - rad + 4, y - rad + 4, x + rad - 4, y + rad - 4]
        md.arc(bbox, start=-90, end=-90 + int(360 * pct), fill=(*accent, 240), width=4)
        font = load_font(14)
        label = f"{int(pct * 100)}"
        bb = md.textbbox((0, 0), label, font=font)
        md.text(
            (x - (bb[2] - bb[0]) / 2, y - (bb[3] - bb[1]) / 2 - 1),
            label,
            font=font,
            fill=(*INK, 220),
        )
    layer.alpha_composite(meters)

    # Comet tip — stream condenses into a directional flare
    tip = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(tip)
    ex, ey = bezier(p0, p1, p2, p3, 0.96)
    dx, dy = bezier_tangent(p0, p1, p2, p3, 0.96)
    length = math.hypot(dx, dy) or 1
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    # Soft elongated glow pointing at Applications
    for i in range(8):
        t = i / 7
        cx = ex + ux * (10 + t * 48)
        cy = ey + uy * (10 + t * 48)
        rr = int(lerp(16, 3, t))
        a = int(lerp(90, 20, t))
        td.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(*CYAN, a))
    # Crisp arrowhead nested in the flare
    tip_len, tip_w = 46, 26
    apex = (ex + ux * tip_len, ey + uy * tip_len)
    left = (ex + ux * 4 + px * tip_w, ey + uy * 4 + py * tip_w)
    right = (ex + ux * 4 - px * tip_w, ey + uy * 4 - py * tip_w)
    td.polygon([apex, left, right], fill=(*HOT, 245))
    # Core spark
    td.ellipse([apex[0] - 4, apex[1] - 4, apex[0] + 4, apex[1] + 4], fill=(255, 255, 255, 200))
    layer.alpha_composite(tip.filter(ImageFilter.GaussianBlur(0.8)))

    # Soft particle dust near stream (creative atmosphere)
    dust = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dust)
    for _ in range(40):
        t = rng.random()
        x, y = bezier(p0, p1, p2, p3, t)
        x += rng.uniform(-40, 40)
        y += rng.uniform(-50, 50)
        r = rng.choice([1, 1, 2])
        dd.ellipse([x - r, y - r, x + r, y + r], fill=(*HOT, rng.randint(20, 70)))
    layer.alpha_composite(dust)


def draw_typography(layer: Image.Image) -> None:
    d = ImageDraw.Draw(layer)

    # Wordmark with slight letter spacing via manual draw
    title = "Cuprim"
    font = load_font(44)
    # Measure total with tracking
    tracking = 4
    widths = []
    for ch in title:
        bb = d.textbbox((0, 0), ch, font=font)
        widths.append(bb[2] - bb[0])
    total = sum(widths) + tracking * (len(title) - 1)
    x = (W - total) / 2
    y = 48
    for ch, w in zip(title, widths):
        d.text((x, y), ch, font=font, fill=(*INK, 245))
        x += w + tracking

    sub = "Your AI quotas, always in sight"
    sf = load_font(20)
    sb = d.textbbox((0, 0), sub, font=sf)
    d.text(((W - (sb[2] - sb[0])) / 2, 104), sub, font=sf, fill=(*SOFT, 210))

    # Quiet install hint — typography only, no fake button
    hint = "Drag into Applications to install"
    hf = load_font(18)
    hb = d.textbbox((0, 0), hint, font=hf)
    hw = hb[2] - hb[0]
    hx = (W - hw) / 2
    hy = H - 56
    d.text((hx, hy), hint, font=hf, fill=(*SOFT, 195))
    # Soft accent dash centered under the line
    dash_w = 36
    d.rounded_rectangle(
        [W // 2 - dash_w // 2, hy + 28, W // 2 + dash_w // 2, hy + 31],
        radius=2,
        fill=(*CYAN, 140),
    )


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out = root / "Design" / "DMG" / "background.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    rng = random.Random(42)

    base = add_film_grain(paint_sky()).convert("RGBA")
    draw_starfield(base, rng)
    draw_menu_bar_wink(base)
    draw_glass_docks(base)
    draw_quota_stream(base, rng)
    draw_typography(base)

    base.convert("RGB").save(out, format="PNG", optimize=True)
    print(f"✓ Wrote {out} ({W}×{H})")


if __name__ == "__main__":
    main()
