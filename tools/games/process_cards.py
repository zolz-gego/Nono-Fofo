#!/usr/bin/env python3
"""Turn the Grandpa's Cards art in design/reference/cards/ into app assets.

- icon.webp (the road card picture, any shape, on white) -> cut out and
  centred on the warm beige square the other road cards use.
- seaside.webp (Alexandria beach, wide) -> the game background (at most
  1920 px wide). "art.background" in app/assets/content/games/cards.json
  points at it.

Run:  tools/.venv/bin/python tools/games/process_cards.py
Out:  app/assets/games/cards.png, app/assets/games/cards_seaside.webp
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_fishing import cut_out  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "cards")
OUT = os.path.join(ROOT, "app", "assets", "games")
ICON_SIZE = 512
# Same warm beige as the other road card pictures (fishing.png, balloons.png).
BEIGE = (237, 228, 207, 255)
# Share of the square the subject may fill.
FILL = 0.84
BACKGROUND_WIDTH = 1920


def main():
    icon_src = os.path.join(SRC, "icon.webp")
    if os.path.exists(icon_src):
        subject = cut_out(Image.open(icon_src))
        k = FILL * ICON_SIZE / max(subject.size)
        subject = subject.resize(
            (round(subject.width * k), round(subject.height * k)), Image.LANCZOS
        )
        card = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), BEIGE)
        card.alpha_composite(
            subject,
            ((ICON_SIZE - subject.width) // 2, (ICON_SIZE - subject.height) // 2),
        )
        card.convert("RGB").save(os.path.join(OUT, "cards.png"), optimize=True)
        print("wrote cards.png")

    sea_src = os.path.join(SRC, "seaside.webp")
    if os.path.exists(sea_src):
        sea = Image.open(sea_src).convert("RGB")
        if sea.width > BACKGROUND_WIDTH:
            sea = sea.resize(
                (BACKGROUND_WIDTH, round(sea.height * BACKGROUND_WIDTH / sea.width)),
                Image.LANCZOS,
            )
        sea.save(os.path.join(OUT, "cards_seaside.webp"), quality=88)
        print("wrote cards_seaside.webp", sea.size)


if __name__ == "__main__":
    main()
