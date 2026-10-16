#!/usr/bin/env python3
"""Turn the writing game art in design/reference/writing/ into app assets.

- study.webp (Grandpa's study, wide) -> the background (resized to 1920 px wide).
- board.webp (one empty green chalkboard on white) -> transparent board,
  stretched to the game's board shape (860 x 580: an 800 x 520 surface and
  a 30-unit frame). The game paints its own green surface inside the frame
  (so the child's drawing can be saved), so only the wooden frame shows.

Then set "art" in app/assets/content/games/writing.json to the line the
script prints.

Run:  tools/.venv/bin/python tools/games/process_writing.py
Out:  app/assets/games/writing_study.webp, app/assets/games/writing_board.png
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from process_fishing import cut_out  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "design", "reference", "writing")
OUT = os.path.join(ROOT, "app", "assets", "games")
BACKGROUND_WIDTH = 1920
# The board's design size in the game, doubled for sharpness.
BOARD_SIZE = (860 * 2, 580 * 2)


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
        board = cut_out(Image.open(board_src)).resize(BOARD_SIZE, Image.LANCZOS)
        board.save(os.path.join(OUT, "writing_board.png"), optimize=True)
        art["board"] = "assets/games/writing_board.png"
        print(f"board {board.width}x{board.height}")
    if not art:
        print(f"nothing to do: put study.webp / board.webp in {os.path.relpath(SRC, ROOT)}")
        return
    print('"art": ' + json.dumps(art))


if __name__ == "__main__":
    main()
