#!/usr/bin/env python3
"""Turn the Nono & Fofo Adventure art in design/reference/adventure/ into
app assets.

- bg_<place>.webp (wide 16:9, repeats sideways) -> level backgrounds.
- ground_<place>.webp (16:9, top edge + earth, repeats sideways) -> top 3%
  trimmed, squeezed
  to 4 tiles wide x 2 tiles tall (512x256), the two ground rows.
- block_<kind>.webp (16:9) -> the middle square, 128x128.
- duck / scorpion / crab / seagull (on white, facing left) -> white
  removed, cropped, 256 px tall.

Missing files are skipped (the game draws those in code).

Run:  tools/.venv/bin/python tools/games/process_adventure.py
Out:  app/assets/games/adventure/*.webp
"""
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "adventure")
OUT = os.path.join(ROOT, "app", "assets", "games", "adventure")

PLACES = ("nile", "desert", "alexandria")
BLOCKS = ("stone", "brick", "question", "used")
ENEMIES = ("duck", "scorpion", "crab", "seagull")
TILE = 128


def save(img, name):
    img.save(os.path.join(OUT, name), "WEBP", quality=90, method=6)
    print(f"{name}: {img.width}x{img.height}")


def without_white(img, threshold=232):
    """Makes the white background (reached from the edges) transparent."""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    seen = bytearray(w * h)
    queue = deque()

    def is_bg(x, y):
        r, g, b, _ = px[x, y]
        return r > threshold and g > threshold and b > threshold

    for x in range(w):
        for y in (0, h - 1):
            queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        i = y * w + x
        if seen[i] or not is_bg(x, y):
            continue
        seen[i] = 1
        px[x, y] = (255, 255, 255, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                queue.append((nx, ny))
    return img.crop(img.getbbox())


def main():
    os.makedirs(OUT, exist_ok=True)

    def src(stem):
        path = os.path.join(SRC, f"{stem}.webp")
        return Image.open(path) if os.path.exists(path) else None

    for place in PLACES:
        bg = src(f"bg_{place}")
        if bg:
            save(bg.convert("RGB"), f"bg_{place}.webp")
        ground = src(f"ground_{place}")
        if ground:
            # Trim the thin background line some pictures have on top.
            w, h = ground.size
            ground = ground.convert("RGB").crop((0, round(h * 0.03), w, h))
            save(ground.resize((TILE * 4, TILE * 2), Image.LANCZOS),
                 f"ground_{place}.webp")
    for kind in BLOCKS:
        block = src(f"block_{kind}")
        if block:
            w, h = block.size
            s = min(w, h)
            square = block.convert("RGB").crop(((w - s) // 2, (h - s) // 2,
                                                 (w + s) // 2, (h + s) // 2))
            save(square.resize((TILE, TILE), Image.LANCZOS), f"block_{kind}.webp")
    for name in ENEMIES:
        enemy = src(name)
        if enemy:
            img = without_white(enemy)
            height = 256
            width = round(img.width * height / img.height)
            save(img.resize((width, height), Image.LANCZOS), f"{name}.webp")


if __name__ == "__main__":
    main()
