"""Find the hollow letter on the writing game's chalkboard (tutorial recordings).

The board draws the letter as a faint white fill (AppColors.letterHollow)
inside a dotted white outline. This closes the dotted outline, keeps the
enclosed parts that carry the lighter fill (so a letter's hole, like the one
in small alpha, is left out) and turns them into chalk rows.

  find_hollow.py <screenshot.png> --scale 3 --origin X,Y --step 8 [--inset 2]
prints JSON (CSS px, offset by --origin):
  {"bbox": [x, y, w, h], "area": css px², "rows": [[x0, x1, y], ...],
   "cols": [[y0, y1, x], ...], "holes": [[x0, x1, y], ...], "holeBox": [x, y, w, h] | null}
cols: the same zigzag top-down (a second pass for corners the rows miss);
holes: rows inside the letter's holes (outside the letter: where to show a mess).
rows go top to bottom, alternating direction (a zigzag), one per run of
letter on each scan line, shrunk by --inset at both ends.
--debug out.png writes the mask over the picture.
"""
import argparse
import json

import numpy as np
from PIL import Image
from scipy import ndimage


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('image')
    ap.add_argument('--scale', type=float, default=3)
    ap.add_argument('--origin', default='0,0')
    ap.add_argument('--step', type=float, default=8, help='CSS px between chalk rows')
    ap.add_argument('--inset', type=float, default=2, help='CSS px kept off each end of a row')
    ap.add_argument('--debug')
    a = ap.parse_args()
    ox, oy = (float(v) for v in a.origin.split(','))
    s = a.scale

    rgb = np.asarray(Image.open(a.image).convert('RGB')).astype(np.int16)
    gray = rgb.mean(axis=2)
    # the outline dots: near white
    dots = (rgb.min(axis=2) > 200)
    # close the gaps between dots (12 board units ≈ 5.6 CSS px apart)
    r = max(2, int(round(4.5 * s)))
    yy, xx = np.ogrid[-r:r + 1, -r:r + 1]
    disk = xx * xx + yy * yy <= r * r
    wall = ndimage.binary_dilation(dots, structure=disk)
    lab, n = ndimage.label(~wall)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    outside = np.isin(lab, list(edge))
    base = np.median(gray[outside]) if outside.any() else np.median(gray)
    inside = np.zeros_like(wall)
    holes = []  # the letter's holes (enclosed, no fill): outside the letter, a place to show a mess
    parts = []
    for i in range(1, n + 1):
        if i in edge:
            continue
        part = lab == i
        if part.sum() >= (8 * s) ** 2:
            parts.append((part, np.median(gray[part])))
    # the faint white fill: the brightest part sets the level (a board smudge
    # over a hole makes it a little lighter than the board, never as light)
    top = max((m for _, m in parts), default=base)
    for part, med in parts:
        if med > base + max(4, 0.6 * (top - base)):
            inside |= part
        else:
            holes.append(part)
    # give back what the dilation took from the letter's own edge
    inside = ndimage.binary_dilation(inside, structure=disk) & ~outside
    # (the hole stays out: it was never "inside")
    if not inside.any():
        print(json.dumps({'bbox': None, 'area': 0, 'rows': []}))
        return
    ys, xs = np.nonzero(inside)
    bbox = [xs.min() / s + ox, ys.min() / s + oy, (xs.max() - xs.min()) / s, (ys.max() - ys.min()) / s]

    def scan(mask, inset, cols=False):
        # zigzag runs over a mask: rows (or columns), each [a0, a1, at] in CSS px
        m = mask.T if cols else mask
        o0, o1 = (oy, ox) if cols else (ox, oy)
        ps, _ = np.nonzero(m)
        out = []
        v = ps.min() + a.step * s * 0.5
        flip = False
        while v < ps.max():
            d = np.diff(np.concatenate([[0], m[int(v)].astype(np.int8), [0]]))
            runs = []
            for x0, x1 in zip(np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]):
                x0c, x1c = x0 / s + inset, x1 / s - inset
                if x1c - x0c < 1:
                    x0c = x1c = (x0 + x1) / 2 / s
                runs.append([round(x0c + o0, 1), round(x1c + o0, 1), round(v / s + o1, 1)])
            if flip:
                runs = [[r1, r0, vv] for r0, r1, vv in reversed(runs)]
            out += runs
            flip = not flip
            v += a.step * s
        return out

    rows = scan(inside, a.inset)
    cols = scan(inside, a.inset, cols=True)
    holes = sorted(holes, key=lambda h: -h.sum())
    hole_rows = [r for h in holes for r in scan(h, a.inset + 2)]
    hole_box = None
    if holes:
        hy, hx = np.nonzero(np.logical_or.reduce(holes))
        hole_box = [round(hx.min() / s + ox, 1), round(hy.min() / s + oy, 1), round((hx.max() - hx.min()) / s, 1), round((hy.max() - hy.min()) / s, 1)]
    if a.debug:
        im = np.asarray(Image.open(a.image).convert('RGB')).copy()
        im[inside] = (im[inside] * 0.4 + np.array([255, 80, 80]) * 0.6).astype(np.uint8)
        Image.fromarray(im).save(a.debug)
    print(json.dumps({'bbox': [round(v, 1) for v in bbox], 'area': round(float(inside.sum()) / s / s), 'rows': rows, 'cols': cols, 'holes': hole_rows, 'holeBox': hole_box}))


if __name__ == '__main__':
    main()
