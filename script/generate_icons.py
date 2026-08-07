#!/usr/bin/env python3
"""Generate Cuprim app-icon layers + monochrome menu-bar template cup PNGs."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BLUE = (0, 115, 235, 255)  # #0073eb
WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)
CLEAR = (0, 0, 0, 0)


def draw_cup(
    img: Image.Image,
    size: int,
    *,
    fill_body=WHITE,
    fill_lid=BLUE,
) -> None:
    """Draw the Cuprim cup mark centered in a square canvas.

    Matches the brand reference: rounded U-body, attached right handle, blue lid.
    """
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
        fill=fill_body,
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
    ImageDraw.Draw(clip).rectangle(
        [cup_right - s * 0.02, 0, size, size],
        fill=255,
    )
    handle_mask = ImageChops.multiply(handle_mask, clip)
    handle_layer = Image.new("RGBA", (size, size), CLEAR)
    handle_layer.paste(fill_body, mask=handle_mask)
    img.alpha_composite(handle_layer)

    lid_left = s * 0.272
    lid_right = s * 0.648
    lid_top = s * 0.318
    lid_bottom = s * 0.390
    lid_r = max(2.0, (lid_bottom - lid_top) * 0.48)
    draw.rounded_rectangle(
        [lid_left, lid_top, lid_right, lid_bottom],
        radius=lid_r,
        fill=fill_lid,
    )


def make_app_layers(size: int = 1024) -> tuple[Image.Image, Image.Image, Image.Image]:
    bg = Image.new("RGBA", (size, size), BLACK)
    fg = Image.new("RGBA", (size, size), CLEAR)
    draw_cup(fg, size)
    composite = bg.copy()
    composite.alpha_composite(fg)
    return bg, fg, composite


def draw_menu_bar_cup_template(img: Image.Image, size: int) -> None:
    """Monochrome black cup on transparent — for isTemplate = true status items."""
    pad = int(round(size * 0.04))
    cup_size = max(8, size - pad * 2)
    cup_layer = Image.new("RGBA", (cup_size, cup_size), CLEAR)
    draw_cup(cup_layer, cup_size, fill_body=BLACK, fill_lid=BLACK)
    ox = (size - cup_size) // 2
    oy = (size - cup_size) // 2
    img.alpha_composite(cup_layer, (ox, oy))


def make_menu_bar_icon(size: int) -> Image.Image:
    """Render far larger than target, then multi-step LANCZOS for sharp alpha edges."""
    if size <= 64:
        big = size * 32
    elif size <= 256:
        big = size * 8
    else:
        big = size * 4

    img = Image.new("RGBA", (big, big), CLEAR)
    draw_menu_bar_cup_template(img, big)

    while img.size[0] > size * 2:
        next_w = max(size, img.size[0] // 2)
        next_h = max(size, img.size[1] // 2)
        img = img.resize((next_w, next_h), Image.Resampling.LANCZOS)
    if img.size[0] != size:
        img = img.resize((size, size), Image.Resampling.LANCZOS)

    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            _, _, _, a = px[x, y]
            if a < 12:
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = (0, 0, 0, a)
    return img


def squircle_mask(size: int) -> Image.Image:
    m = Image.new("L", (size, size), 0)
    rr = int(size * 0.223)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size - 1, size - 1], radius=rr, fill=255)
    return m


def apply_squircle(img: Image.Image) -> Image.Image:
    out = Image.new("RGBA", img.size, CLEAR)
    out.paste(img, (0, 0))
    out.putalpha(squircle_mask(img.size[0]))
    return out


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG", optimize=True)
    print(f"  wrote {path.relative_to(ROOT)} ({img.size[0]}×{img.size[1]})")


def main() -> None:
    print("→ App icon layers (cup mark)")
    bg, fg, composite = make_app_layers(1024)
    layers = ROOT / "Design/AppIcon/Layers"
    exports = ROOT / "Design/AppIcon/Exports"
    assets = ROOT / "Sources/Cuprim/Resources/AppIcon/AppIcon.icon/Assets"
    res = ROOT / "Sources/Cuprim/Resources/AppIcon"

    save_png(bg, layers / "Background.png")
    save_png(fg, layers / "Foreground.png")
    save_png(composite, exports / "Preview-Cup-Composite-1024.png")
    save_png(bg, assets / "Background.png")
    save_png(fg, assets / "Foreground.png")
    save_png(composite, res / "AppIcon-1024.png")
    save_png(composite, res / "AppIcon-About.png")
    save_png(composite, exports / "Cuprim-Default-1024.png")
    save_png(composite, exports / "Cuprim-Dark-1024.png")
    save_png(apply_squircle(composite), ROOT / "Design/AppIcon/Preview-Composite-1024.png")

    print("→ Menu bar template cup (monochrome isTemplate)")
    mb = ROOT / "Sources/Cuprim/Resources/MenuBar"
    save_png(make_menu_bar_icon(1024), mb / "MenuBarIcon-master.png")
    for name, px in [
        ("MenuBarIcon.png", 18),
        ("MenuBarIcon@2x.png", 36),
        ("MenuBarIcon@3x.png", 54),
        ("MenuBarIcon-16.png", 16),
        ("MenuBarIcon-16@2x.png", 32),
    ]:
        save_png(make_menu_bar_icon(px), mb / name)

    master = Image.open(mb / "MenuBarIcon-master.png").convert("RGBA")
    preview = Image.new("RGBA", (256, 256), (40, 40, 44, 255))
    small = master.resize((180, 180), Image.Resampling.LANCZOS)
    inked = Image.new("RGBA", small.size, CLEAR)
    sp, ip = small.load(), inked.load()
    for y in range(small.size[1]):
        for x in range(small.size[0]):
            _, _, _, a = sp[x, y]
            if a > 10:
                ip[x, y] = (230, 230, 235, a)
    preview.alpha_composite(inked, ((256 - 180) // 2, (256 - 180) // 2))
    save_png(preview, ROOT / "Design/MenuBar/preview-on-dark.png")

    print("→ Website favicons (cup mark)")
    public = ROOT / "website/public"
    for name, px in [
        ("icon-source.png", 1024),
        ("icon-512.png", 512),
        ("icon-192.png", 192),
        ("favicon.png", 32),
    ]:
        render = px if px >= 256 else 256
        _, _, c = make_app_layers(render)
        if c.size[0] != px:
            c = c.resize((px, px), Image.Resampling.LANCZOS)
        save_png(apply_squircle(c), public / name)

    ico_imgs = []
    for s in (16, 32, 48):
        _, _, c = make_app_layers(256)
        ico_imgs.append(apply_squircle(c.resize((s, s), Image.Resampling.LANCZOS)))
    ico_path = public / "favicon.ico"
    ico_imgs[0].save(
        ico_path,
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48)],
        append_images=ico_imgs[1:],
    )
    print(f"  wrote {ico_path.relative_to(ROOT)}")
    print("✓ Icon assets generated")


if __name__ == "__main__":
    main()
