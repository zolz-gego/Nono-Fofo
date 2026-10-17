#!/usr/bin/env python3
"""Find the hiding spots for Search the Monastery from the real art.

For every room in app/assets/content/games/monastery.json this places the
objects (their cut-out pictures at their "rect") over the room, then looks
for points where a letter would be about half hidden behind an object:
enough shows to find it, not so much that it's obvious. It keeps a spread of
them (a few per object, not over the windows' sky) and writes them as the
room's "spots". A preview with every spot circled goes to
design/reference/monastery/preview_<room>.png.

Run it again after moving an object or swapping a picture:
    tools/.venv/bin/python tools/games/monastery_spots.py
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
APP = os.path.join(ROOT, "app")
CONFIG = os.path.join(APP, "assets", "content", "games", "monastery.json")
PREVIEW = os.path.join(ROOT, "design", "reference", "monastery")

# Letter size (font size, as a share of the room's height) per room.
LETTER_SIZE = {"wide": 0.075, "tall": 0.055}
# The letter's ink, roughly: a disc this share of the font size across.
INK = 0.62
# How much of the letter should be hidden.
HIDDEN = (0.4, 0.68)
BEST_HIDDEN = 0.55
# Spots at least this far apart (room heights); the game spaces the ones it
# picks further apart still (minSpotGap).
GAP = 0.065
PER_OBJECT = 3
MAX_SPOTS = 26
WORK_HEIGHT = 720
# Nothing up in the ceiling beams.
TOP_MARGIN = 0.08


def disc_fraction(mask, radius):
    """For every pixel: the share of a disc around it that is in [mask]."""
    H, W = mask.shape
    r = int(round(radius))
    yy, xx = np.mgrid[-r : r + 1, -r : r + 1]
    disc = (xx * xx + yy * yy <= r * r).astype(np.float64)
    ph, pw = H + 2 * r + 1, W + 2 * r + 1
    big = np.fft.rfft2(np.pad(mask.astype(np.float64), ((0, 2 * r + 1), (0, 2 * r + 1))), (ph, pw))
    k = np.fft.rfft2(disc, (ph, pw))
    conv = np.fft.irfft2(big * k, (ph, pw))[r : r + H, r : r + W]
    return conv / disc.sum()


def compose(scene, W, H):
    room = Image.open(os.path.join(APP, scene["background"])).convert("RGBA").resize((W, H))
    owner = np.full((H, W), -1)
    for i, o in enumerate(scene["objects"]):
        x, y, w, h = o["rect"]
        box = (round(x * W), round(y * H), round(w * W), round(h * H))
        pic = Image.open(os.path.join(APP, o["image"])).convert("RGBA").resize(box[2:])
        room.alpha_composite(pic, box[:2])
        a = np.asarray(pic.getchannel("A")) > 128
        sub = owner[box[1] : box[1] + box[3], box[0] : box[0] + box[2]]
        sub[a[: sub.shape[0], : sub.shape[1]]] = i
    return room, owner


def spots_for(scene):
    H = WORK_HEIGHT
    W = round(H * scene["aspect"])
    room, owner = compose(scene, W, H)
    size = LETTER_SIZE.get(scene["id"], 0.07)
    radius = size * H * INK / 2
    hidden = disc_fraction(owner >= 0, radius)
    rgb = np.asarray(room.convert("RGB")).astype(int)
    sky = (rgb[..., 2] > rgb[..., 0] + 25) & (owner < 0)
    on_sky = disc_fraction(sky, radius)

    step = max(2, int(H * 0.01))
    m = int(radius) + 2
    cands = []
    for y in range(max(m, int(TOP_MARGIN * H)), H - m, step):
        for x in range(m, W - m, step):
            f = hidden[y, x]
            if HIDDEN[0] <= f <= HIDDEN[1] and on_sky[y, x] < 0.05:
                # The object hiding most of it.
                r = int(radius)
                patch = owner[y - r : y + r + 1, x - r : x + r + 1]
                ids, counts = np.unique(patch[patch >= 0], return_counts=True)
                cands.append((abs(f - BEST_HIDDEN), x, y, int(ids[np.argmax(counts)])))
    cands.sort()

    chosen, per = [], {}
    for _, x, y, obj in cands:
        if per.get(obj, 0) >= PER_OBJECT:
            continue
        if any(np.hypot(x - cx, y - cy) < GAP * H for cx, cy, _ in chosen):
            continue
        chosen.append((x, y, obj))
        per[obj] = per.get(obj, 0) + 1
        if len(chosen) >= MAX_SPOTS:
            break

    draw = ImageDraw.Draw(room)
    for x, y, _ in chosen:
        r = size * H * 0.75
        draw.ellipse((x - r, y - r, x + r, y + r), outline=(230, 60, 60, 255), width=3)
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), outline=(60, 60, 230, 255), width=2)
    room.convert("RGB").save(os.path.join(PREVIEW, f"preview_{scene['id']}.png"))

    names = [o["id"] for o in scene["objects"]]
    print(scene["id"], len(chosen), "spots:", {names[k]: v for k, v in sorted(per.items())})
    return [
        {"x": round(x / W, 3), "y": round(y / H, 3), "size": size}
        for x, y, _ in sorted(chosen, key=lambda c: (c[1], c[0]))
    ]


def dump(x, ind=0):
    """JSON with each object / spot on one line."""
    pad = "  " * ind
    if isinstance(x, dict):
        flat = all(
            not isinstance(v, (dict, list))
            or (isinstance(v, list) and all(isinstance(e, (int, float)) for e in v))
            for v in x.values()
        )
        if flat and ind > 2:
            parts = [f"{json.dumps(k)}: {dump(v)}" for k, v in x.items()]
            return "{ " + ", ".join(parts) + " }"
        items = [f"{pad}  {json.dumps(k, ensure_ascii=False)}: {dump(v, ind + 1)}" for k, v in x.items()]
        return "{\n" + ",\n".join(items) + "\n" + pad + "}"
    if isinstance(x, list):
        if all(isinstance(e, (int, float, str)) for e in x) and len(json.dumps(x)) < 100:
            return "[" + ", ".join(json.dumps(e, ensure_ascii=False) for e in x) + "]"
        return "[\n" + ",\n".join(pad + "  " + dump(e, ind + 1) for e in x) + "\n" + pad + "]"
    return json.dumps(x, ensure_ascii=False)


def main():
    with open(CONFIG, encoding="utf-8") as f:
        config = json.load(f)
    for scene in config["scenes"]:
        scene["spots"] = spots_for(scene)
    with open(CONFIG, "w", encoding="utf-8") as f:
        f.write(dump(config) + "\n")


if __name__ == "__main__":
    main()
