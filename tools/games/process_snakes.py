#!/usr/bin/env python3
"""Turn the Snakes & Ladders art in design/reference/snakes/ into app assets.

- pyramids.webp (wide 16:9) -> the background behind the board (at most
  1920 px on the long side). pyramids_tall.webp, if there, -> the phone one.
- ladder.webp (one ladder on white, pointing up) -> cut out (the white
  between the rungs too), trimmed.
- snake_green.webp (one snake on white, head at the top) -> cut out and
  trimmed, then recoloured into the other snake colours (only the green
  body and its light spots change hue; eyes and tongue stay). A
  snake_<colour>.webp in the folder replaces the recoloured one.

The board stretches the ladder and snakes between their squares, so their
exact size doesn't matter.

Run:  tools/.venv/bin/python tools/games/process_snakes.py
Out:  app/assets/games/snakes/*.webp
"""
import colorsys
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_monastery import cut_out, fit  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "snakes")
OUT = os.path.join(ROOT, "app", "assets", "games", "snakes")
BACKGROUND_MAX = 1920
PIECE_MAX = 900

# Snake colours (match AppColors.snakes order in the app): name -> hex.
SNAKES = {
    "green": "#6CC24A",
    "coral": "#FF7A5C",
    "lilac": "#B57EDC",
    "mint": "#3FBFA0",
    "orange": "#FF9F43",
}


def hue_of(hex_color):
    r, g, b = (int(hex_color[i : i + 2], 16) / 255 for i in (1, 3, 5))
    return colorsys.rgb_to_hsv(r, g, b)[0]


def recolour(img, to_hex):
    """Shifts the green body (and its yellow-green spots) to [to_hex]'s hue."""
    a = np.asarray(img.convert("RGBA")).astype(np.float32) / 255
    rgb, alpha = a[..., :3], a[..., 3:]
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    v = mx
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    d = np.maximum(mx - mn, 1e-6)
    h = np.select(
        [mx == r, mx == g],
        [((g - b) / d) % 6, (b - r) / d + 2],
        (r - g) / d + 4,
    ) / 6
    # Green to yellow-green, with some colour: the body and the spots.
    body = (h > 40 / 360) & (h < 160 / 360) & (s > 0.18)
    # Shift from the body's real hue (the picture's green, not the hex).
    shift = hue_of(to_hex) - float(np.median(h[body & (alpha[..., 0] > 0.5)]))
    h2 = np.where(body, (h + shift) % 1, h)
    # HSV -> RGB.
    i = np.floor(h2 * 6).astype(int) % 6
    f = h2 * 6 - np.floor(h2 * 6)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    out = np.choose(
        i[..., None].repeat(3, axis=2).transpose(2, 0, 1),
        [
            np.stack([v, t, p]),
            np.stack([q, v, p]),
            np.stack([p, v, t]),
            np.stack([p, q, v]),
            np.stack([t, p, v]),
            np.stack([v, p, q]),
        ],
    ).transpose(1, 2, 0)
    rgba = np.concatenate([out, alpha], axis=2)
    return Image.fromarray((rgba * 255).round().astype(np.uint8), "RGBA")


def save(img, name):
    path = os.path.join(OUT, name)
    img.save(path, "WEBP", quality=90, method=6)
    print(f"{name}: {img.width}x{img.height}")


def main():
    os.makedirs(OUT, exist_ok=True)
    for stem in ("pyramids", "pyramids_tall"):
        src = os.path.join(SRC, f"{stem}.webp")
        if os.path.exists(src):
            save(fit(Image.open(src).convert("RGB"), BACKGROUND_MAX), f"{stem}.webp")

    save(fit(cut_out(Image.open(os.path.join(SRC, "ladder.webp"))), PIECE_MAX), "ladder.webp")

    green = fit(cut_out(Image.open(os.path.join(SRC, "snake_green.webp"))), PIECE_MAX)
    for name, hex_color in SNAKES.items():
        own = os.path.join(SRC, f"snake_{name}.webp")
        if name != "green" and os.path.exists(own):
            img = fit(cut_out(Image.open(own)), PIECE_MAX)
        else:
            img = green if name == "green" else recolour(green, hex_color)
        save(img, f"snake_{name}.webp")


if __name__ == "__main__":
    main()
