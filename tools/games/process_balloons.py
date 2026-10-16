#!/usr/bin/env python3
"""Turn the balloons game art in design/reference/balloons/ into app assets.

- balloon.webp (one ORANGE balloon on white, no string) -> transparent
  balloon in 8 colors: only the orange rubber is re-colored; outline, shine
  and the cream letter circle stay as drawn.
- village.webp -> the background (resized to 1920 px wide).

Prints where the letter circle sits; put it in "balloonLetterSpot" in
app/assets/content/games/balloons.json, and list the balloon files in
"balloonImages" (the script prints that line too).

Run:  tools/.venv/bin/python tools/games/process_balloons.py
Out:  app/assets/games/balloons/balloon_<color>.png, village.webp
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_fishing import COLORS, cut_out, letter_spot, recolor  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "balloons")
OUT = os.path.join(ROOT, "app", "assets", "games", "balloons")
# Output width of each balloon, px.
WIDTH = 300
BACKGROUND_WIDTH = 1920


def main():
    os.makedirs(OUT, exist_ok=True)
    balloon_src = os.path.join(SRC, "balloon.webp")
    if os.path.exists(balloon_src):
        balloon = cut_out(Image.open(balloon_src))
        balloon = balloon.resize(
            (WIDTH, round(balloon.height * WIDTH / balloon.width)), Image.LANCZOS
        )
        x, y, r = letter_spot(balloon)
        files = []
        for name, (hue, sat) in COLORS.items():
            recolor(balloon, hue, sat).save(
                os.path.join(OUT, f"balloon_{name}.png"), optimize=True
            )
            files.append(f'"assets/games/balloons/balloon_{name}.png"')
            print("balloon", name)
        # letter_spot gives the radius as a fraction of the height; the game
        # sizes the letter from the width.
        size = r * 2 * balloon.height / balloon.width
        print(f"size {balloon.width}x{balloon.height}")
        print(f'"balloonLetterSpot": {{ "x": {x:.3f}, "y": {y:.3f}, "size": {size:.3f} }}')
        print(f'"balloonImages": [{", ".join(files)}]')
    village_src = os.path.join(SRC, "village.webp")
    if os.path.exists(village_src):
        village = Image.open(village_src).convert("RGB")
        if village.width > BACKGROUND_WIDTH:
            village = village.resize(
                (BACKGROUND_WIDTH, round(village.height * BACKGROUND_WIDTH / village.width)),
                Image.LANCZOS,
            )
        village.save(os.path.join(OUT, "village.webp"), quality=88)
        print(f"village {village.width}x{village.height}")


if __name__ == "__main__":
    main()
