#!/usr/bin/env python3
"""Turn the Search the Monastery art in design/reference/monastery/ into
app assets.

- room.webp (wide 16:9) and room_tall.webp (phones, 9:16) -> the empty room
  backgrounds (at most 1920 px on the long side).
- Every other picture is one object on white -> cut out (the white around it
  AND the white holes inside it, like between chair slats or under the
  bench), trimmed to the object, at most 900 px on the long side.
- icon.webp, if there, -> the road card (cut out, on the beige square).
- level_5.webp ... level_10.webp, if there, -> the level tile pictures (cut
  out, trimmed); "levelArt" in the JSON is pointed at them.

The scene's "rect" for each object in app/assets/content/games/monastery.json
should keep the trimmed picture's shape; the script prints each one's
width / height to help.

Run:  tools/.venv/bin/python tools/games/process_monastery.py
Out:  app/assets/games/monastery/*.png|webp, app/assets/games/monastery.png
"""
import json
import os
import re
import sys
from collections import deque

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_fishing import flood_white  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "monastery")
OUT = os.path.join(ROOT, "app", "assets", "games", "monastery")
ICON_OUT = os.path.join(ROOT, "app", "assets", "games", "monastery.png")
CONFIG = os.path.join(ROOT, "app", "assets", "content", "games", "monastery.json")
LEVEL_MAX = 360
ROOMS = {"room": "room.webp", "room_tall": "room_tall.webp"}
ROOM_MAX = 1920
OBJECT_MAX = 900
# White holes inside an object smaller than this (pixels) are kept: they are
# highlights, not background showing through.
MIN_HOLE = 120
ICON_SIZE = 512
BEIGE = (237, 228, 207, 255)
FILL = 0.84


def white_holes(rgb, outside):
    """Neutral white areas inside the object (not touching the border)."""
    neutral = (rgb.min(axis=2) > 238) & (rgb.max(axis=2) - rgb.min(axis=2) < 10)
    neutral &= ~outside
    H, W = neutral.shape
    seen = np.zeros_like(neutral)
    holes = np.zeros_like(neutral)
    for y0, x0 in zip(*np.nonzero(neutral)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and neutral[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        if len(pts) >= MIN_HOLE:
            ys, xs = zip(*pts)
            holes[list(ys), list(xs)] = True
    return holes


def cut_out(img):
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    outside = flood_white(rgb)
    bg = outside | white_holes(rgb, outside)
    # Soft edge: alpha from how far a pixel next to the background is from
    # white.
    soft = np.clip(np.max((255.0 - rgb) / 255.0, axis=2) * 3, 0, 1)
    edge = np.zeros_like(bg)
    edge[1:, :] |= bg[:-1, :]
    edge[:-1, :] |= bg[1:, :]
    edge[:, 1:] |= bg[:, :-1]
    edge[:, :-1] |= bg[:, 1:]
    edge &= ~bg
    alpha = np.where(bg, 0.0, np.where(edge, soft, 1.0))
    out = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    rgba = Image.fromarray(out, "RGBA")
    return rgba.crop(rgba.getchannel("A").getbbox())


def fit(img, longest):
    k = longest / max(img.size)
    if k >= 1:
        return img
    return img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    level_art = {}
    for name in sorted(os.listdir(SRC)):
        stem, ext = os.path.splitext(name)
        # preview_*.png are monastery_spots.py's previews, not art.
        if ext.lower() not in (".webp", ".png", ".jpg", ".jpeg") or stem.startswith("preview_"):
            continue
        img = Image.open(os.path.join(SRC, name))
        if stem in ROOMS:
            room = fit(img.convert("RGB"), ROOM_MAX)
            room.save(os.path.join(OUT, ROOMS[stem]), quality=88)
            print(f"{ROOMS[stem]:16} {room.size}  aspect {room.width / room.height:.4f}")
        elif re.fullmatch(r"level_\d+", stem):
            tile = fit(cut_out(img), LEVEL_MAX)
            tile.save(os.path.join(OUT, f"{stem}.png"), optimize=True)
            level_art[stem.split("_")[1]] = f"assets/games/monastery/{stem}.png"
            print(f"{stem + '.png':16} {tile.size}")
        elif stem == "icon":
            subject = cut_out(img)
            k = FILL * ICON_SIZE / max(subject.size)
            subject = subject.resize(
                (round(subject.width * k), round(subject.height * k)), Image.LANCZOS
            )
            card = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), BEIGE)
            card.alpha_composite(
                subject,
                ((ICON_SIZE - subject.width) // 2, (ICON_SIZE - subject.height) // 2),
            )
            card.convert("RGB").save(ICON_OUT, optimize=True)
            print("monastery.png (road card)")
        else:
            obj = fit(cut_out(img), OBJECT_MAX)
            obj.save(os.path.join(OUT, f"{stem}.png"), optimize=True)
            print(f"{stem + '.png':16} {obj.size}  w/h {obj.width / obj.height:.4f}")
    if level_art:
        with open(CONFIG, encoding="utf-8") as f:
            text = f.read()
        art = json.dumps(dict(sorted(level_art.items(), key=lambda e: int(e[0]))))
        text = re.sub(r'"levelArt": \{[^}]*\}', f'"levelArt": {art}', text)
        with open(CONFIG, "w", encoding="utf-8") as f:
            f.write(text)
        print("levelArt ->", art)


if __name__ == "__main__":
    main()
