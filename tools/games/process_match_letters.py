#!/usr/bin/env python3
"""Turn the Match the letters art in design/reference/match_letters/ into app assets.

- icon.webp -> the road card (cut out, on the beige square). The game itself
  reuses the Snakes & Ladders Pyramids background, so it has no picture of
  its own. (icon_original.webp is the picture as generated; in icon.webp the
  ⲏ line that went to ن was moved to start at ⲛ, so every pair is right.)

Run:  tools/.venv/bin/python tools/games/process_match_letters.py
Out:  app/assets/games/matchLetters.png
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_monastery import BEIGE, FILL, ICON_SIZE, cut_out  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "match_letters")
ICON_OUT = os.path.join(ROOT, "app", "assets", "games", "matchLetters.png")


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
    print("matchLetters.png (road card)")


if __name__ == "__main__":
    main()
