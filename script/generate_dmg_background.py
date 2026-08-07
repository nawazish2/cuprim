#!/usr/bin/env python3
"""
Cuprim DMG art — “Paper Pour”

Quiet paper/ink field with a soft cup watermark and a blue pour-chevron
guiding Cuprim.app → Applications. Matches the cup mark (#0073eb lid) without
Raycast neon, keyboard photos, or purple-AI tropes.

Finder window: 660×400pt · art @2x (1320×800).
Icon centers (pt): Cuprim.app (150, 185) · Applications (510, 185)
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 660 * 2, 400 * 2

# Purge paper/ink + brand blue
PAPER = (244, 246, 243)  # #f4f6f3
INK = (24, 27, 23)  # #181b17
BLUE = (0, 115, 235)  # #0073eb
MIST = (228, 232, 226)
WASH = (252, 253, 251)

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


def paint_paper() -> Image.Image:
    """Soft paper field with cool wash and gentle vignette — not flat gray."""
    img = Image.new("RGB", (W, H), PAPER)
    px = img.load()
    assert px is not None
    cx, cy = W / 2, H * 0.42
    for y in range(H):
        vt = y / (H - 1)
        for x in range(W):
            ht = x / (W - 1)
            # Vertical cool→warm paper drift
            r = int(lerp(WASH[0], PAPER[0], vt * 0.85))
            g = int(lerp(WASH[1], PAPER[1], vt * 0.85))
            b = int(lerp(WASH[2], MIST[2], vt * 0.55 + ht * 0.1))
            # Soft central lift (room for icons)
            dx = (x - cx) / (W * 0.55)
            dy = (y - cy) / (H * 0.55)
            lift = max(0.0, 1.0 - math.sqrt(dx * dx + dy * dy)) ** 2
            r = min(255, int(r + 8 * lift))
            g = min(255, int(g + 8 * lift))
            b = min(255, int(b + 6 * lift))
            # Quiet brand-blue bloom between docks (very soft)
            mx = (ICON_L[0] + ICON_R[0]) / 2
            my = ICON_L[1]
            d = math.hypot((x - mx) / 320, (y - my) / 140)
            w = max(0.0, 1.0 - d) ** 2 * 0.07
            r = min(255, int(r + BLUE[0] * w * 0.35))
            g = min(255, int(g + BLUE[1] * w * 0.35))
            b = min(255, int(b + BLUE[2] * w * 0.55))
            # Edge vignette toward ink mist
            edge = min(x, W - 1 - x, y, H - 1 - y) / 200.0
            edge = max(0.0, min(1.0, edge))
            k = 0.92 + 0.08 * edge
            px[x, y] = (int(r * k), int(g * k), int(b * k))
    return img


def add_paper_grain(img: Image.Image) -> Image.Image:
    out = img.copy()
    px = out.load()
    assert px is not None
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            n = ((x * 73 + y * 149) % 11) - 5
            if abs(n) < 2:
                continue
            r, g, b = px[x, y]
            px[x, y] = (
                max(0, min(255, r + n)),
                max(0, min(255, g + n)),
                max(0, min(255, b + n)),
            )
    return out.filter(ImageFilter.GaussianBlur(0.35))


def draw_cup_mark(
    size: int,
    *,
    body=(255, 255, 255, 255),
    lid=(*BLUE, 255),
) -> Image.Image:
    """Cup geometry aligned with script/generate_icons.py (simplified)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = float(size)

    cup_left = s * 0.30
    cup_right = s * 0.62
    cup_top = s * 0.378
    cup_bottom = s * 0.78
    radius = (cup_right - cup_left) * 0.42
    draw.rounded_rectangle(
        [cup_left, cup_top, cup_right, cup_bottom],
        radius=radius,
        fill=body,
    )

    hx0 = cup_right - s * 0.045
    hx1 = s * 0.80
    hy0 = s * 0.43
    hy1 = s * 0.70
    outer = Image.new("L", (size, size), 0)
    inner = Image.new("L", (size, size), 0)
    ImageDraw.Draw(outer).ellipse([hx0, hy0, hx1, hy1], fill=255)
    inset = s * 0.055
    ImageDraw.Draw(inner).ellipse(
        [hx0 + inset, hy0 + inset, hx1 - inset, hy1 - inset],
        fill=255,
    )
    handle_mask = ImageChops.subtract(outer, inner)
    clip = Image.new("L", (size, size), 0)
    ImageDraw.Draw(clip).rectangle([cup_right - s * 0.02, 0, size, size], fill=255)
    handle_mask = ImageChops.multiply(handle_mask, clip)
    handle_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    handle_layer.paste(body, mask=handle_mask)
    img.alpha_composite(handle_layer)

    lid_left = s * 0.272
    lid_right = s * 0.648
    lid_top = s * 0.318
    lid_bottom = s * 0.390
    lid_r = max(2.0, (lid_bottom - lid_top) * 0.48)
    draw.rounded_rectangle(
        [lid_left, lid_top, lid_right, lid_bottom],
        radius=lid_r,
        fill=lid,
    )
    return img


def draw_cup_watermark(layer: Image.Image) -> None:
    """Large faint cup — atmosphere, not competing with Finder icons."""
    size = 520
    cup = draw_cup_mark(
        size,
        body=(INK[0], INK[1], INK[2], 18),
        lid=(*BLUE, 28),
    )
    # Place lower-right, partly cropped — a quiet brand ghost
    ox = W - size + 40
    oy = H - size + 80
    layer.alpha_composite(cup, (ox, oy))


def draw_menu_bar_wink(layer: Image.Image) -> None:
    """Whisper of a menu bar — where Cuprim lives."""
    d = ImageDraw.Draw(layer)
    y = 36
    left, right = W // 2 - 130, W // 2 + 130
    d.rounded_rectangle(
        [left, y, right, y + 10],
        radius=5,
        fill=(INK[0], INK[1], INK[2], 18),
    )
    # Status dots
    for ox, a in ((-78, 55), (-52, 55), (78, 55)):
        d.ellipse(
            [W // 2 + ox - 2, y + 3, W // 2 + ox + 2, y + 7],
            fill=(INK[0], INK[1], INK[2], a),
        )
    # Cuprim status — blue lid wink
    d.ellipse([W // 2 - 6, y + 1, W // 2 + 6, y + 9], fill=(*BLUE, 200))
    d.ellipse([W // 2 - 3, y + 3, W // 2 + 3, y + 7], fill=(255, 255, 255, 220))


def draw_landing_pads(layer: Image.Image) -> None:
    """Soft elliptical docks under Finder icons — paper shadow, not neon glow."""
    for cx, cy in (ICON_L, ICON_R):
        pad = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(pad)
        d.ellipse(
            [cx - 100, cy + 52, cx + 100, cy + 108],
            fill=(INK[0], INK[1], INK[2], 22),
        )
        layer.alpha_composite(pad.filter(ImageFilter.GaussianBlur(10)))

        rim = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        rd = ImageDraw.Draw(rim)
        rd.ellipse(
            [cx - 92, cy + 58, cx + 92, cy + 100],
            fill=(255, 255, 255, 40),
            outline=(INK[0], INK[1], INK[2], 28),
            width=1,
        )
        layer.alpha_composite(rim.filter(ImageFilter.GaussianBlur(1.2)))


def draw_pour_chevrons(layer: Image.Image) -> None:
    """Three blue chevrons pointing right — install direction, Cuprim blue."""
    mid_x = (ICON_L[0] + ICON_R[0]) / 2
    mid_y = ICON_L[1] - 4
    # Soft connecting wash (pour trail)
    trail = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td = ImageDraw.Draw(trail)
    span = ICON_R[0] - ICON_L[0] - 220
    for i in range(18):
        t = i / 17
        x = ICON_L[0] + 110 + span * t
        # Gentle arc — pour dip
        y = mid_y + math.sin(t * math.pi) * 18
        r = int(lerp(10, 6, abs(t - 0.5) * 2))
        a = int(lerp(18, 36, 1 - abs(t - 0.5) * 2))
        td.ellipse([x - r, y - r, x + r, y + r], fill=(*BLUE, a))
    layer.alpha_composite(trail.filter(ImageFilter.GaussianBlur(8)))

    chevs = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chevs)
    # Three chevrons, increasing emphasis toward Applications
    positions = (-56, 0, 56)
    alphas = (110, 160, 210)
    for ox, alpha in zip(positions, alphas):
        cx = mid_x + ox
        cy = mid_y
        # Chevron as thick ">" made of two strokes (readable, not neon)
        tip = (cx + 22, cy)
        top = (cx - 14, cy - 22)
        bot = (cx - 14, cy + 22)
        # Soft underglow in brand blue only
        cd.line([top, tip], fill=(*BLUE, alpha // 3), width=14)
        cd.line([bot, tip], fill=(*BLUE, alpha // 3), width=14)
        cd.line([top, tip], fill=(*BLUE, alpha), width=6)
        cd.line([bot, tip], fill=(*BLUE, alpha), width=6)
        # Ink core for crispness on paper
        cd.line([top, tip], fill=(INK[0], INK[1], INK[2], alpha // 4), width=2)
        cd.line([bot, tip], fill=(INK[0], INK[1], INK[2], alpha // 4), width=2)
    layer.alpha_composite(chevs.filter(ImageFilter.GaussianBlur(0.4)))


def draw_typography(layer: Image.Image) -> None:
    d = ImageDraw.Draw(layer)

    title = "Cuprim"
    font = load_font(46)
    tracking = 5
    widths = []
    for ch in title:
        bb = d.textbbox((0, 0), ch, font=font)
        widths.append(bb[2] - bb[0])
    total = sum(widths) + tracking * (len(title) - 1)
    x = (W - total) / 2
    y = 58
    for ch, w in zip(title, widths):
        d.text((x, y), ch, font=font, fill=(INK[0], INK[1], INK[2], 235))
        x += w + tracking

    sub = "Your AI quotas, always in sight"
    sf = load_font(20)
    sb = d.textbbox((0, 0), sub, font=sf)
    d.text(
        ((W - (sb[2] - sb[0])) / 2, 118),
        sub,
        font=sf,
        fill=(INK[0], INK[1], INK[2], 130),
    )

    hint = "Drag into Applications to install"
    hf = load_font(18)
    hb = d.textbbox((0, 0), hint, font=hf)
    hw = hb[2] - hb[0]
    hx = (W - hw) / 2
    hy = H - 58
    d.text((hx, hy), hint, font=hf, fill=(INK[0], INK[1], INK[2], 140))
    dash_w = 40
    d.rounded_rectangle(
        [W // 2 - dash_w // 2, hy + 28, W // 2 + dash_w // 2, hy + 32],
        radius=2,
        fill=(*BLUE, 180),
    )


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    out = root / "Design" / "DMG" / "background.png"
    out.parent.mkdir(parents=True, exist_ok=True)

    base = add_paper_grain(paint_paper()).convert("RGBA")
    draw_cup_watermark(base)
    draw_menu_bar_wink(base)
    draw_landing_pads(base)
    draw_pour_chevrons(base)
    draw_typography(base)

    base.convert("RGB").save(out, format="PNG", optimize=True)
    print(f"✓ Wrote {out} ({W}×{H})")


if __name__ == "__main__":
    main()
