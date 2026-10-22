#!/usr/bin/env python3
"""Turn the Magic basket art in design/reference/magic_basket/ into app assets.

- tree.webp   -> the apple tree, cut out (at most 1600 px wide).
- apple.webp  -> one apple with an empty cream circle, cut out. Prints where
  the circle sits ("appleLetterSpot" in magic_basket.json).
- basket.webp -> the basket, cut out. Prints the middle of its opening
  ("basketOpening" in magic_basket.json): apples sit there, and the part of
  the basket below that line is drawn again over them.
- icon.webp   -> the road card (cut out, on the beige square).

Run:  tools/.venv/bin/python tools/games/process_magic_basket.py
Out:  app/assets/games/magic_basket/*.png, app/assets/games/magicBasket.png
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_fishing import letter_spot  # noqa: E402
from process_monastery import BEIGE, FILL, ICON_SIZE, cut_out, fit  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "magic_basket")
OUT = os.path.join(ROOT, "app", "assets", "games", "magic_basket")
ICON_OUT = os.path.join(ROOT, "app", "assets", "games", "magicBasket.png")
MAX = {"tree": 1600, "apple": 300, "basket": 500}


def opening(rgba):
    """Middle of the basket's opening: the rows where the light rim is
    widest at its top and front edges; returns the y halfway between them,
    as a fraction of the height."""
    a = np.asarray(rgba).astype(int)
    light = (a[..., 0] > 225) & (a[..., 1] > 205) & (a[..., 2] > 170) & (a[..., 3] > 250)
    rows = np.nonzero(light.sum(axis=1) > rgba.width * 0.04)[0]
    return (rows.min() + rows.max()) / 2 / rgba.height


def main():
    os.makedirs(OUT, exist_ok=True)
    for stem in ("tree", "apple", "basket"):
        src = os.path.join(SRC, f"{stem}.webp")
        if not os.path.exists(src):
            continue
        img = fit(cut_out(Image.open(src)), MAX[stem])
        img.save(os.path.join(OUT, f"{stem}.png"), optimize=True)
        print(f"{stem}.png {img.size}  w/h {img.width / img.height:.4f}")
        if stem == "apple":
            x, y, r = letter_spot(img)
            size = r * 2 * img.height / img.width
            print(f'"appleLetterSpot": {{ "x": {x:.3f}, "y": {y:.3f}, "size": {size:.3f} }}')
        if stem == "basket":
            print(f'"basketOpening": {opening(img):.3f}')
    icon = os.path.join(SRC, "icon.webp")
    if os.path.exists(icon):
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
        print("magicBasket.png (road card)")


if __name__ == "__main__":
    main()
