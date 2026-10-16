#!/usr/bin/env python3
"""Turn the writing game art in design/reference/writing/ into app assets.

- study.webp (Grandpa's study, wide) -> the background (resized to 1920 px wide).
- board.webp (one empty green chalkboard on white) -> transparent board.
  The script finds the green surface inside the frame and prints where it
  is ("boardSurface", fractions of the picture); the game paints its own
  chalk surface exactly there (so the child's drawing can be saved) and
  stretches the picture so the frame goes around it.

Then set "art" in app/assets/content/games/writing.json to the line the
script prints.

Run:  tools/.venv/bin/python tools/games/process_writing.py
Out:  app/assets/games/writing_study.webp, app/assets/games/writing_board.png
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_fishing import cut_out  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "writing")
OUT = os.path.join(ROOT, "app", "assets", "games")
BACKGROUND_WIDTH = 1920
BOARD_WIDTH = 1600


def green_box(rgba):
    """Bounding box of the green chalk surface, as fractions of the image."""
    a = np.asarray(rgba).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    green = (g - r > 25) & (g >= b) & (al > 200)
    # Ignore stray pixels: keep rows/columns that are mostly green.
    rows = np.where(green.mean(axis=1) > 0.5)[0]
    cols = np.where(green.mean(axis=0) > 0.5)[0]
    h, w = green.shape
    return {
        "left": round(cols[0] / w, 4),
        "top": round(rows[0] / h, 4),
        "right": round((cols[-1] + 1) / w, 4),
        "bottom": round((rows[-1] + 1) / h, 4),
    }


def main():
    art = {}
    study_src = os.path.join(SRC, "study.webp")
    if os.path.exists(study_src):
        study = Image.open(study_src).convert("RGB")
        if study.width > BACKGROUND_WIDTH:
            study = study.resize(
                (BACKGROUND_WIDTH, round(study.height * BACKGROUND_WIDTH / study.width)),
                Image.LANCZOS,
            )
        study.save(os.path.join(OUT, "writing_study.webp"), quality=88)
        art["background"] = "assets/games/writing_study.webp"
        print(f"study {study.width}x{study.height}")
    board_src = os.path.join(SRC, "board.webp")
    if os.path.exists(board_src):
        board = cut_out(Image.open(board_src))
        if board.width > BOARD_WIDTH:
            board = board.resize(
                (BOARD_WIDTH, round(board.height * BOARD_WIDTH / board.width)), Image.LANCZOS
            )
        board.save(os.path.join(OUT, "writing_board.png"), optimize=True)
        art["board"] = "assets/games/writing_board.png"
        art["boardSurface"] = green_box(board)
        print(f"board {board.width}x{board.height}")
    if not art:
        print(f"nothing to do: put study.webp / board.webp in {os.path.relpath(SRC, ROOT)}")
        return
    print('"art": ' + json.dumps(art))


if __name__ == "__main__":
    main()
