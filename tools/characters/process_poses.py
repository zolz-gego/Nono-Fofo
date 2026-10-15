#!/usr/bin/env python3
"""Turn the Gemini pose images in Characters/ into app-ready PNGs.

For every pose: apply small per-image fixes, remove the white background
(keeping soft edges and the ground shadow as transparency), trim, and scale
so both brothers share one size system (Fofo is 75% of Nono's height).

Run:  tools/.venv/bin/python tools/characters/process_poses.py
Out:  app/assets/characters/<name>/<pose>.png        full size
      assets/characters/<name>/small/<pose>.png  256px tall, for icons and pickers
      assets/characters/manifest.json
"""
import json
import os
from collections import deque

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "Characters")
OUT = os.path.join(ROOT, "app", "assets", "characters")

# Source file for each pose. Swap a file name here when a pose is regenerated.
SOURCES = {
    "nono": {
        "idle": "Nono idle.jpeg", "cheer": "Nono cheer.jpeg", "wrong": "nono oops.jpeg",
        "hint": "Nono Hint.jpeg", "celebrate": "Nono Celebrate.jpeg", "encourage": "Nono Encourage.jpeg",
        "run": "Nono Run.jpeg", "wave": "Nono hello.jpeg", "write": "Nono Write.jpeg",
        "read": "Nono Read.jpeg", "sleep": "Nono Sleep.jpeg", "surprised": "Nono surprised.jpeg",
    },
    "fofo": {
        "idle": "Fofo idle.jpeg", "cheer": "Fofo Cheer.jpeg", "wrong": "Fofo oops.jpeg",
        "hint": "Fofo Hint.jpeg", "celebrate": "Fofo Celebrate.jpeg", "encourage": "Fofo Encourage.jpeg",
        "run": "Fofo Run.jpeg", "wave": "Fofo Hello.jpeg", "write": "Fofo Write 2.jpeg",
        "read": "Fofo Read.jpeg", "sleep": "Fofo Sleep.jpeg", "surprised": "Fofo Surprised.jpeg",
    },
}

# Closed gaps (e.g. between an arm and the body) that the edge flood can't reach.
# (x, y) seed points in source pixels, after fix_source.
HOLES = {
    ("nono", "wrong"): [(362, 249)],
    ("nono", "encourage"): [(594, 489)],
    ("fofo", "idle"): [(460, 630)],
}

# Head (hair) width in the output, in px. Fofo is smaller, like in the approved lineup.
HEAD_W = {"nono": 300, "fofo": 262}
SMALL_H = 256


def fix_source(name, pose, img):
    """Per-image clean-ups, in source pixel coordinates."""
    # some exports have a faint grey line on the outer edge
    img = img.crop((3, 3, img.width - 3, img.height - 3))
    d = ImageDraw.Draw(img)
    W, H = img.size
    if (name, pose) == ("fofo", "idle"):
        # the image shows a front and a side view; keep the front one
        img = img.crop((0, 0, 620, H))
    elif (name, pose) == ("fofo", "celebrate"):
        # lightbulb belongs to the hint pose
        d.rectangle((560, 0, 720, 175), fill="white")
    elif (name, pose) == ("nono", "sleep"):
        # remove the drawn floor line on both sides of the body
        d.rectangle((140, 850, 338, 868), fill="white")
        d.rectangle((706, 850, 880, 868), fill="white")
    return img


def flood_background(rgb, seeds=()):
    """Pixels connected to the border (or a seed) that are light and nearly grey (paper or shadow)."""
    r, g, b = (rgb[..., i].astype(int) for i in range(3))
    mx, mn = np.maximum(np.maximum(r, g), b), np.minimum(np.minimum(r, g), b)
    grey = (mx - mn) < 22
    H, W = grey.shape
    # Paper is light grey/white. The ground shadow is darker grey, so it is only
    # allowed in a thin strip at the shoe soles (keeps white socks and eyes safe).
    dark_rows = np.nonzero((mn < 110).any(axis=1))[0]
    ground = dark_rows.max() if len(dark_rows) else H
    band = np.zeros((H, 1), bool)
    band[max(0, ground - int(H * 0.03)):] = True
    cand = grey & ((mn > 165) | ((mn > 100) & band))
    seen = np.zeros_like(cand)
    q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if cand[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    for y in range(H):
        for x in (0, W - 1):
            if cand[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    for x, y in seeds:
        seen[y, x] = True
        q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < H and 0 <= nx < W and cand[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))
    return seen


def large_closed_gaps(rgb, bg, min_area=6000):
    """Big white areas the flood can't reach, like the space between legs.
    Socks, teeth and eye whites are far smaller than min_area."""
    mn, mx = rgb.min(axis=2), rgb.max(axis=2)
    white = (mn > 200) & ((mx - mn) < 20) & ~bg
    H, W = white.shape
    seen = np.zeros_like(white)
    out = np.zeros_like(white)
    for y0, x0 in zip(*np.nonzero(white)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and white[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        if len(pts) >= min_area:
            ys, xs = zip(*pts)
            out[list(ys), list(xs)] = True
    return out


def remove_white(img, seeds=()):
    """'Color to alpha' against white, applied to the background and a thin edge band."""
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    bg = flood_background(rgb, seeds)
    bg |= large_closed_gaps(rgb, bg)
    band = np.asarray(Image.fromarray((bg * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))) > 0
    zone = band  # background plus 2px of edge
    a = np.max((255.0 - rgb) / 255.0, axis=2)
    a = np.where(a < 0.08, 0.0, a)  # JPEG noise on the paper
    alpha = np.where(zone, a, 1.0)
    safe = np.maximum(alpha, 1e-3)[..., None]
    col = np.where(zone[..., None], (rgb - 255.0 * (1 - safe)) / safe, rgb)
    out = np.dstack([np.clip(col, 0, 255), np.clip(alpha * 255, 0, 255)]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def hair_mask(name, rgba):
    a = np.asarray(rgba).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    if name == "nono":
        m = (lum < 95) & (r >= g) & (g >= b) & (al > 200)
    else:
        m = (lum > 70) & (lum < 150) & ((r - b) > 70) & (g < 130) & (al > 200)
    # opening removes thin outlines and line art, keeps the big hair mass
    im = Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.MinFilter(9)).filter(ImageFilter.MaxFilter(9))
    return np.asarray(im) > 0


def largest_blob_bbox(mask, step=4):
    small = mask[::step, ::step]
    H, W = small.shape
    seen = np.zeros_like(small)
    best = None
    for y0, x0 in zip(*np.nonzero(small)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and small[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        if best is None or len(pts) > len(best):
            best = pts
    ys, xs = zip(*best)
    return min(xs) * step, min(ys) * step, (max(xs) + 1) * step, (max(ys) + 1) * step


def drop_specks(rgba, min_area=40):
    """Remove tiny leftover dots (JPEG noise) that are not confetti or props."""
    a = np.asarray(rgba).copy()
    solid = a[..., 3] > 40
    H, W = solid.shape
    seen = np.zeros_like(solid)
    for y0, x0 in zip(*np.nonzero(solid)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)])
        seen[y0, x0] = True
        pts = []
        while q:
            y, x = q.popleft()
            pts.append((y, x))
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < H and 0 <= nx < W and solid[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    q.append((ny, nx))
        if len(pts) < min_area:
            ys, xs = zip(*pts)
            a[list(ys), list(xs), 3] = 0
    return Image.fromarray(a, "RGBA")


def main():
    manifest = {"version": 1, "head_width": HEAD_W, "characters": {}}
    for name, poses in SOURCES.items():
        os.makedirs(os.path.join(OUT, name, "small"), exist_ok=True)
        manifest["characters"][name] = {}
        for pose, fn in poses.items():
            img = Image.open(os.path.join(SRC, fn)).convert("RGB")
            img = fix_source(name, pose, img)
            rgba = drop_specks(remove_white(img, HOLES.get((name, pose), ())))
            hx0, hy0, hx1, hy1 = largest_blob_bbox(hair_mask(name, rgba))
            scale = HEAD_W[name] / max(1, hx1 - hx0)
            bbox = rgba.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
            pad = 12
            box = (max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                   min(rgba.width, bbox[2] + pad), min(rgba.height, bbox[3] + pad))
            cut = rgba.crop(box)
            size = (round(cut.width * scale), round(cut.height * scale))
            full = cut.resize(size, Image.LANCZOS)
            full.save(os.path.join(OUT, name, f"{pose}.png"), optimize=True)
            sw = round(full.width * SMALL_H / full.height)
            full.resize((sw, SMALL_H), Image.LANCZOS).save(os.path.join(OUT, name, "small", f"{pose}.png"), optimize=True)
            manifest["characters"][name][pose] = {
                "file": f"{name}/{pose}.png", "small": f"{name}/small/{pose}.png",
                "width": full.width, "height": full.height, "source": fn,
                # head centre, so the app can line poses up when switching
                "head_center": [round(((hx0 + hx1) / 2 - box[0]) * scale), round(((hy0 + hy1) / 2 - box[1]) * scale)],
            }
            print(f"{name:5} {pose:10} {full.width}x{full.height}  head {hx1 - hx0}px -> x{scale:.2f}")
    with open(os.path.join(OUT, "manifest.json"), "w") as fh:
        json.dump(manifest, fh, indent=2)


if __name__ == "__main__":
    main()
