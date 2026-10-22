#!/usr/bin/env python3
"""Turn the Letter puzzle art in design/reference/letter_puzzle/ into app assets.

- church.webp -> the background inside the church (at most 1920 px wide).
- icon.webp   -> the road card (cut out, on the beige square).

Run:  tools/.venv/bin/python tools/games/process_letter_puzzle.py
Out:  app/assets/games/letter_puzzle/church.webp, app/assets/games/letterPuzzle.png
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_monastery import BEIGE, FILL, ICON_SIZE, cut_out  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "letter_puzzle")
OUT = os.path.join(ROOT, "app", "assets", "games", "letter_puzzle")
ICON_OUT = os.path.join(ROOT, "app", "assets", "games", "letterPuzzle.png")
MAX_WIDTH = 1920


def main():
    os.makedirs(OUT, exist_ok=True)
    church = os.path.join(SRC, "church.webp")
    if os.path.exists(church):
        img = Image.open(church).convert("RGB")
        if img.width > MAX_WIDTH:
            img = img.resize(
                (MAX_WIDTH, round(img.height * MAX_WIDTH / img.width)), Image.LANCZOS
            )
        img.save(os.path.join(OUT, "church.webp"), quality=85)
        print(f"church.webp {img.size}")
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
        print("letterPuzzle.png (road card)")


if __name__ == "__main__":
    main()
