#!/usr/bin/env python3
"""Turn the Where's the letter art in design/reference/where_letter/ into app assets.

- icon.webp -> the road card (cut out, on the beige square). The game itself
  reuses the Letter puzzle church background, so it has no picture of its
  own. The picture came with a cream wall and a sand floor instead of white,
  so they're cut away here (flood from the border over colours close to
  either, plus the thin brown line where they meet).

Run:  tools/.venv/bin/python tools/games/process_where_letter.py
Out:  app/assets/games/whereLetter.png
"""
import os
import sys
from collections import deque

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_monastery import BEIGE, FILL, ICON_SIZE  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "where_letter")
ICON_OUT = os.path.join(ROOT, "app", "assets", "games", "whereLetter.png")

WALL = (243, 226, 178)
FLOOR = (238, 195, 118)
TOLERANCE = 30

# How far the wall/floor line may be from background on both sides.
LINE_REACH = 6


def background(rgb):
    """Wall and floor pixels reachable from the border."""
    H, W, _ = rgb.shape
    near = np.zeros((H, W), bool)
    for c in (WALL, FLOOR):
        near |= np.sqrt(((rgb - np.array(c, np.float32)) ** 2).sum(axis=2)) < TOLERANCE
    bg = np.zeros_like(near)
    q = deque()
    for y in range(H):
        for x in (0, W - 1):
            if near[y, x] and not bg[y, x]:
                bg[y, x] = True
                q.append((y, x))
    for x in range(W):
        for y in (0, H - 1):
            if near[y, x] and not bg[y, x]:
                bg[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < H and 0 <= nx < W and near[ny, nx] and not bg[ny, nx]:
                bg[ny, nx] = True
                q.append((ny, nx))
    # The line between wall and floor: background just above and below.
    above = np.zeros_like(bg)
    below = np.zeros_like(bg)
    for d in range(1, LINE_REACH + 1):
        above[d:, :] |= bg[:-d, :]
        below[:-d, :] |= bg[d:, :]
    return drop_specks(bg | (above & below))


# Smaller bits left after the cut (ends of the wall/floor line) go too.
MIN_PART = 3000


def drop_specks(bg):
    H, W = bg.shape
    seen = bg.copy()
    for y0, x0 in zip(*np.nonzero(~bg)):
        if seen[y0, x0]:
            continue
        seen[y0, x0] = True
        q = deque([(y0, x0)])
        part = []
        while q:
            y, x = q.popleft()
            part.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        if len(part) < MIN_PART:
            ys, xs = zip(*part)
            bg[list(ys), list(xs)] = True
    return bg


def cut_out(img):
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    alpha = np.where(background(rgb), 0, 255).astype(np.uint8)
    rgba = Image.fromarray(np.dstack([rgb.astype(np.uint8), alpha]), "RGBA")
    return rgba.crop(rgba.getchannel("A").getbbox())


def main():
    icon = os.path.join(SRC, "icon.webp")
    if not os.path.exists(icon):
        sys.exit(f"Missing {icon}")
    subject = cut_out(Image.open(icon))
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
    print("whereLetter.png (road card)")


if __name__ == "__main__":
    main()
