#!/usr/bin/env python3
"""Turn the round Gemini logo in design/brand/ into the in-app logo and every app icon.

The source is a teal ring on a white background, slightly taller than wide.
We cut out the ring with an anti-aliased ellipse (a few px inside the edge,
so no white fringe), squash it to a true circle, then compose:
  - transparent round logo for the app top bar, web icons and favicon
  - square icons with the ring color as background (iOS, Android legacy)
  - padded icons for safe zones (web maskable, Android adaptive foreground)

Run:  tools/.venv/bin/python tools/brand/process_logo.py
"""
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "brand", "logo-source.jpg")
APP = os.path.join(ROOT, "app")

INSET = 3          # px trimmed off the ring's outer edge to drop the white fringe
SUPERSAMPLE = 4    # for a smooth mask edge


def cut_circle(src: Image.Image) -> Image.Image:
    rgb = np.asarray(src.convert("RGB")).astype(int)
    dark = rgb.sum(2) < 450
    ys, xs = np.where(dark)
    box = (xs.min() + INSET, ys.min() + INSET, xs.max() - INSET + 1, ys.max() - INSET + 1)

    big = Image.new("L", (src.width * SUPERSAMPLE, src.height * SUPERSAMPLE), 0)
    ImageDraw.Draw(big).ellipse([v * SUPERSAMPLE for v in box], fill=255)
    mask = big.resize(src.size, Image.LANCZOS)

    out = src.convert("RGBA")
    out.putalpha(mask)
    out = out.crop(box)
    side = max(out.size)
    return out.resize((side, side), Image.LANCZOS)


def ring_color(src: Image.Image) -> tuple:
    rgb = np.asarray(src.convert("RGB")).astype(int)
    # The ring sits at the very top-middle of the source.
    patch = rgb[8:24, src.width // 2 - 40: src.width // 2 + 40].reshape(-1, 3)
    return tuple(int(v) for v in np.median(patch, axis=0))


def on_square(logo: Image.Image, size: int, scale: float, bg) -> Image.Image:
    """Logo centered on a size x size canvas, its diameter = scale * size."""
    canvas = Image.new("RGBA", (size, size), bg)
    d = round(size * scale)
    canvas.alpha_composite(logo.resize((d, d), Image.LANCZOS), ((size - d) // 2, (size - d) // 2))
    return canvas


def save(img: Image.Image, *path, rgb=False):
    p = os.path.join(APP, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    (img.convert("RGB") if rgb else img).save(p, optimize=True)
    print("wrote", os.path.relpath(p, ROOT))


def main():
    src = Image.open(SRC)
    logo = cut_circle(src)
    bg = ring_color(src) + (255,)
    clear = (0, 0, 0, 0)

    # In-app logo (top bar, later the splash).
    save(logo.resize((512, 512), Image.LANCZOS), "assets", "brand", "logo.png")

    # Web.
    save(logo.resize((32, 32), Image.LANCZOS), "web", "favicon.png")
    for s in (192, 512):
        save(on_square(logo, s, 1.0, clear), "web", "icons", f"Icon-{s}.png")
        save(on_square(logo, s, 0.8, bg), "web", "icons", f"Icon-maskable-{s}.png")

    # iOS: full-bleed square, no alpha (iOS rounds the corners itself).
    ios = os.path.join("ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    for name, px in {
        "20x20@1x": 20, "20x20@2x": 40, "20x20@3x": 60,
        "29x29@1x": 29, "29x29@2x": 58, "29x29@3x": 87,
        "40x40@1x": 40, "40x40@2x": 80, "40x40@3x": 120,
        "60x60@2x": 120, "60x60@3x": 180,
        "76x76@1x": 76, "76x76@2x": 152, "83.5x83.5@2x": 167,
        "1024x1024@1x": 1024,
    }.items():
        save(on_square(logo, px, 1.0, bg), ios, f"Icon-App-{name}.png", rgb=True)

    # Android: legacy square icon + adaptive foreground (logo inside the 66% safe zone).
    res = os.path.join("android", "app", "src", "main", "res")
    for dpi, legacy in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        save(on_square(logo, legacy, 1.0, bg), res, f"mipmap-{dpi}", "ic_launcher.png")
        fg = legacy * 108 // 48
        save(on_square(logo, fg, 0.66, clear), res, f"mipmap-{dpi}", "ic_launcher_foreground.png")

    print("ring color #%02X%02X%02X" % bg[:3])


if __name__ == "__main__":
    main()
