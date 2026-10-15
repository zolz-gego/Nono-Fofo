#!/usr/bin/env python3
"""Turn the fishing game art in design/reference/fishing/ into app assets.

- fish.webp (one orange fish on white) -> transparent fish in 8 colors:
  only the orange body/fins/belly are re-colored; outlines, eye, cheek,
  mouth and the cream letter circle stay as drawn.
- nile.webp -> copied as the background.

Prints where the letter circle sits; put it in "fishLetterSpot" in
app/assets/content/games/fishing.json.

Run:  tools/.venv/bin/python tools/games/process_fishing.py
Out:  app/assets/games/fishing/fish_<color>.png, nile.webp
"""
import colorsys
import os
import shutil
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "fishing")
OUT = os.path.join(ROOT, "app", "assets", "games", "fishing")

# Target hue (degrees) and saturation factor for each color; the drawn fish
# is orange (~28°). Some hues turn neon at full saturation, so they're softened.
COLORS = {
    "orange": (28, 1.0), "coral": (8, 0.85), "yellow": (46, 1.0), "green": (100, 0.62),
    "mint": (162, 0.7), "blue": (198, 0.8), "lilac": (272, 0.5), "pink": (328, 0.62),
}
SOURCE_HUE = 28
# Output width of each fish, px.
WIDTH = 360


def flood_white(rgb):
    """Near-white pixels connected to the border."""
    near = rgb.min(axis=2) > 225
    H, W = near.shape
    seen = np.zeros_like(near)
    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if near[y, x]:
                seen[y, x] = True
                q.append((y, x))
    for y in range(H):
        for x in (0, W - 1):
            if near[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < H and 0 <= nx < W and near[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))
    return seen


def cut_out(img):
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    bg = flood_white(rgb)
    # soft edge: alpha from how far a background-adjacent pixel is from white
    a = np.clip(np.max((255.0 - rgb) / 255.0, axis=2) * 3, 0, 1)
    alpha = np.where(bg, 0.0, 1.0)
    edge = np.zeros_like(bg)
    edge[1:, :] |= bg[:-1, :]
    edge[:-1, :] |= bg[1:, :]
    edge[:, 1:] |= bg[:, :-1]
    edge[:, :-1] |= bg[:, 1:]
    edge &= ~bg
    alpha = np.where(edge, a, alpha)
    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    rgba = Image.fromarray(out, "RGBA")
    return rgba.crop(rgba.getchannel("A").getbbox())


def letter_spot(rgba):
    """Center and radius of the cream circle, as fractions of the image."""
    a = np.asarray(rgba).astype(int)
    cream = (a[..., 0] > 235) & (a[..., 1] > 230) & (a[..., 2] > 215) & (a[..., 3] > 250)
    H, W = cream.shape
    # largest cream blob (the eye highlight and white are much smaller)
    seen = np.zeros_like(cream)
    best = []
    for y0, x0 in zip(*np.nonzero(cream[::4, ::4])):
        y0, x0 = y0 * 4, x0 * 4
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and cream[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        if len(pts) > len(best):
            best = pts
    ys, xs = zip(*best)
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    r = (max(xs) - min(xs)) / 2
    return cx / W, cy / H, r / H


def recolor(rgba, target_hue, sat):
    a = np.asarray(rgba).astype(np.float32) / 255.0
    out = a.copy()
    shift = ((target_hue - SOURCE_HUE) % 360) / 360.0
    rgb_to_hsv = np.vectorize(colorsys.rgb_to_hsv)
    hsv_to_rgb = np.vectorize(colorsys.hsv_to_rgb)
    h, s, v = rgb_to_hsv(a[..., 0], a[..., 1], a[..., 2])
    hue_deg = h * 360
    # orange body, fins and pale belly; not the brown outline (dark),
    # not the pink cheek/red mouth, not the cream circle (low saturation)
    body = (hue_deg > 14) & (hue_deg < 50) & (s > 0.28) & (v > 0.55) & (a[..., 3] > 0)
    nh = np.where(body, (h + shift) % 1.0, h)
    ns = np.where(body, s * sat, s)
    r, g, b = hsv_to_rgb(nh, ns, v)
    out[..., 0], out[..., 1], out[..., 2] = r, g, b
    return Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")


def main():
    os.makedirs(OUT, exist_ok=True)
    fish = cut_out(Image.open(os.path.join(SRC, "fish.webp")))
    fish = fish.resize((WIDTH, round(fish.height * WIDTH / fish.width)), Image.LANCZOS)
    x, y, r = letter_spot(fish)
    for name, (hue, sat) in COLORS.items():
        recolor(fish, hue, sat).save(os.path.join(OUT, f"fish_{name}.png"), optimize=True)
        print("fish", name)
    shutil.copy(os.path.join(SRC, "nile.webp"), os.path.join(OUT, "nile.webp"))
    print(f'size {fish.width}x{fish.height}  "fishLetterSpot": {{ "x": {x:.3f}, "y": {y:.3f}, "size": {r * 2:.3f} }}')


if __name__ == "__main__":
    main()
