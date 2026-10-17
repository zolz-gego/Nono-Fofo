#!/usr/bin/env python3
"""Turn the Snakes & Ladders background in design/reference/snakes/ into an
app asset.

- pyramids.webp (wide 16:9) -> the background behind the board (at most
  1920 px on the long side). pyramids_tall.webp, if there, -> the phone one.

The board, its snakes and its ladders are drawn in code (so they always sit
on their exact squares).

Run:  tools/.venv/bin/python tools/games/process_snakes.py
Out:  app/assets/games/snakes/*.webp
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_monastery import fit  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "snakes")
OUT = os.path.join(ROOT, "app", "assets", "games", "snakes")
BACKGROUND_MAX = 1920


def main():
    os.makedirs(OUT, exist_ok=True)
    for stem in ("pyramids", "pyramids_tall"):
        src = os.path.join(SRC, f"{stem}.webp")
        if not os.path.exists(src):
            continue
        img = fit(Image.open(src).convert("RGB"), BACKGROUND_MAX)
        img.save(os.path.join(OUT, f"{stem}.webp"), "WEBP", quality=90, method=6)
        print(f"{stem}.webp: {img.width}x{img.height}")


if __name__ == "__main__":
    main()
