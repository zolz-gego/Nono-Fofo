#!/usr/bin/env python3
"""Find the Coptic letters drawn on cream badges in a game screenshot.

Games like fishing draw their letters on a canvas, so the page has no buttons
for them. This finds every cream badge (fish patch, balloon tag...), reads its
letter by comparing the glyph with the app's Avva Shenouda font, and prints
JSON: [{"x", "y", "r", "key", "score"}] in screenshot pixels, best first.

Run:  tools/.venv/bin/python social/tools/tutorial/find_letters.py <shot.png> <keys> [--top 0.45]
      <keys>: the Avva keys that can appear, comma separated (e.g. "a,b,e,z,3,i,k,l,m,n,o,c,t,w").
      --top: ignore everything above this fraction of the height (HUD, sky).
Serve mode (used by the recorder): --serve reads "<png> <keys> <top>" lines on stdin
and writes one JSON line per request, so numpy/PIL load only once.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
FONT = os.path.join(ROOT, "app", "assets", "fonts", "Avva_Shenouda.ttf")
CREAM = np.array([254, 250, 242])
N = 28  # normalized glyph size
_refs = {}


def norm(mask):
    """Crop a glyph mask to its box, pad it square and scale it to N×N."""
    ys, xs = np.nonzero(mask)
    if len(xs) < 6:
        return None
    m = mask[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    h, w = m.shape
    s = max(h, w)
    sq = np.zeros((s, s), bool)
    sq[(s - h) // 2:(s - h) // 2 + h, (s - w) // 2:(s - w) // 2 + w] = m
    img = Image.fromarray((sq * 255).astype(np.uint8)).resize((N, N), Image.BILINEAR)
    return np.asarray(img) > 100


def ref(key):
    if key not in _refs:
        font = ImageFont.truetype(FONT, 120)
        img = Image.new("L", (240, 240), 0)
        ImageDraw.Draw(img).text((40, 20), key, font=font, fill=255)
        _refs[key] = norm(np.asarray(img) > 128)
    return _refs[key]


def find(path, keys, top=0.45):
    im = np.asarray(Image.open(path).convert("RGB")).astype(int)
    H, W, _ = im.shape
    cream = np.abs(im - CREAM).sum(axis=2) < 24
    cream[: int(H * top)] = False
    lab, n = ndimage.label(cream)
    out = []
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        ys, xs = sl
        h, w = ys.stop - ys.start, xs.stop - xs.start
        area = (lab[sl] == i).sum()
        # a badge is a round filled patch: roughly square, mostly cream
        if h < H * 0.025 or w < H * 0.025 or not (0.7 < w / h < 1.4) or area < 0.45 * w * h:
            continue
        crop = im[sl]
        cy, cx = np.mgrid[0:h, 0:w]
        inside = ((cx - w / 2) / (w / 2)) ** 2 + ((cy - h / 2) / (h / 2)) ** 2 < 0.72
        dark = (crop.sum(axis=2) < 520) & inside
        g = norm(dark)
        if g is None:
            continue
        scores = {k: (g & ref(k)).sum() / max(1, (g | ref(k)).sum()) for k in keys}
        best = max(scores, key=scores.get)
        out.append({"x": xs.start + w / 2, "y": ys.start + h / 2, "r": max(w, h) / 2, "key": best, "score": round(scores[best], 3)})
    return sorted(out, key=lambda b: -b["score"])


if __name__ == "__main__":
    if "--serve" in sys.argv:
        for line in sys.stdin:
            path, keys, top = line.split()
            print(json.dumps(find(path, keys.split(","), float(top))), flush=True)
    else:
        top = float(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 0.45
        print(json.dumps(find(sys.argv[1], sys.argv[2].split(","), top), indent=1))
