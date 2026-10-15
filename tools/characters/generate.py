#!/usr/bin/env python3
"""Generate Nono & Fofo character poses as flat 2D SVGs.

Every pose is built from the same parts (legs, shorts, shirt, arms, head,
hair, face, props), so both brothers stay on-model. Edit a pose in POSES
and re-run:  python3 tools/characters/generate.py
Output: assets/characters/<name>/<pose>.svg
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "app", "assets", "characters")

W, H = 300, 400
CX, GROUND = 150, 388

# Brand palette + playful accents
C = {
    "teal": "#0F4C5C", "seafoam": "#A8DADC", "sand": "#EFE6D8",
    "mist": "#4F7C82", "drift": "#5B4B3A",
    "yellow": "#FFC93C", "coral": "#FF6B5B", "green": "#6BCB77",
    "skin": "#C98A5E", "skin_dark": "#A86F47", "hair": "#2A1B12",
    "line": "#1E2B2F", "white": "#FFFFFF", "blush": "#FF8A7A",
}
LW = 3.5  # outline width

CHARS = {
    "nono": dict(
        head_r=56, head_y=136, shoulder_y=202, waist_y=256, hip_y=286,
        torso_top=68, torso_bot=62, shoulder_dx=31, hip_dx=14,
        arm=(38, 36), arm_w=17, leg=(46, 46), leg_w=19,
        shirt=C["teal"], trim=C["yellow"], shorts=C["drift"],
        shoe=C["coral"], shoe_rx=16, hair="spiky", glasses=False,
    ),
    "fofo": dict(
        head_r=60, head_y=190, shoulder_y=256, waist_y=302, hip_y=328,
        torso_top=78, torso_bot=90, shoulder_dx=37, hip_dx=17,
        arm=(28, 27), arm_w=18, leg=(26, 25), leg_w=21,
        shirt=C["seafoam"], trim=C["green"], shorts=C["mist"],
        shoe=C["yellow"], shoe_rx=16, hair="curly", glasses=True,
    ),
}


# ---------- geometry helpers ----------
def f(n):
    return f"{n:.1f}".rstrip("0").rstrip(".")


def from_angles(start, side, lengths, angles):
    """Angles in degrees: 0 = down, 90 = sideways out, 180 = up, negative = inward."""
    pts = [start]
    x, y = start
    for L, a in zip(lengths, angles):
        r = math.radians(a)
        x, y = x + side * L * math.sin(r), y + L * math.cos(r)
        pts.append((x, y))
    return pts


def ik(start, target, lengths, side, center_x=CX):
    """Two-bone IK: returns [shoulder, elbow, hand] with elbow pushed outward."""
    (sx, sy), (tx, ty) = start, target
    L1, L2 = lengths
    dx, dy = tx - sx, ty - sy
    d = max(abs(L1 - L2) + 1, min(math.hypot(dx, dy), L1 + L2 - 0.5))
    base = math.atan2(dy, dx)
    a = math.acos((L1 * L1 + d * d - L2 * L2) / (2 * L1 * d))
    cands = []
    for s in (1, -1):
        e = (sx + L1 * math.cos(base + s * a), sy + L1 * math.sin(base + s * a))
        cands.append(e)
    elbow = max(cands, key=lambda e: side * (e[0] - center_x))
    hand = (sx + d * math.cos(base), sy + d * math.sin(base))
    return [start, elbow, hand]


def poly_stroke(pts, width, color, outline=True):
    d = "M" + " L".join(f"{f(x)},{f(y)}" for x, y in pts)
    s = ""
    if outline:
        s += f'<path d="{d}" fill="none" stroke="{C["line"]}" stroke-width="{f(width + LW * 2)}" stroke-linecap="round" stroke-linejoin="round"/>'
    s += f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{f(width)}" stroke-linecap="round" stroke-linejoin="round"/>'
    return s


def circle(x, y, r, fill, stroke=True, extra=""):
    st = f' stroke="{C["line"]}" stroke-width="{LW}"' if stroke else ""
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{fill}"{st}{extra}/>'


def ellipse(x, y, rx, ry, fill, stroke=True, rot=0, extra=""):
    st = f' stroke="{C["line"]}" stroke-width="{LW}"' if stroke else ""
    tr = f' transform="rotate({f(rot)} {f(x)} {f(y)})"' if rot else ""
    return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(rx)}" ry="{f(ry)}" fill="{fill}"{st}{tr}{extra}/>'


def star(x, y, r, fill, rot=0):
    pts = []
    for i in range(10):
        rr = r if i % 2 == 0 else r * 0.45
        a = math.radians(-90 + i * 36 + rot)
        pts.append(f"{f(x + rr * math.cos(a))},{f(y + rr * math.sin(a))}")
    return f'<polygon points="{" ".join(pts)}" fill="{fill}" stroke="{C["line"]}" stroke-width="2.5" stroke-linejoin="round"/>'


# ---------- body parts ----------
def leg(ch, side, angles):
    hip = (CX + side * ch["hip_dx"], ch["hip_y"])
    pts = from_angles(hip, side, ch["leg"], angles)
    s = poly_stroke(pts, ch["leg_w"], C["skin"])
    # sock
    fx, fy = pts[-1]
    px, py = pts[-2]
    k = 10 / max(1, math.hypot(fx - px, fy - py))
    s += poly_stroke([(fx - (fx - px) * k, fy - (fy - py) * k), (fx, fy)], ch["leg_w"] + 1, C["white"])
    # shoe: points outward, sits under the foot
    rx = ch["shoe_rx"]
    sx = fx + side * 5
    s += ellipse(sx, fy + 5, rx, rx * 0.6, ch["shoe"])
    s += f'<path d="M{f(sx - rx * 0.8)},{f(fy + 9)} Q{f(sx)},{f(fy + 14)} {f(sx + rx * 0.8)},{f(fy + 9)}" fill="none" stroke="{C["white"]}" stroke-width="3" stroke-linecap="round"/>'
    return s


def shorts(ch):
    t, b = ch["waist_y"] - 4, ch["hip_y"] + 16
    hw = ch["torso_bot"] / 2 + 2
    lw = ch["hip_dx"] + ch["leg_w"] / 2 + 6
    d = (f"M{f(CX - hw)},{f(t)} L{f(CX + hw)},{f(t)} L{f(CX + lw + 4)},{f(b)} "
         f"L{f(CX + 3)},{f(b)} L{f(CX)},{f(ch['hip_y'] + 2)} L{f(CX - 3)},{f(b)} L{f(CX - lw - 4)},{f(b)} Z")
    return f'<path d="{d}" fill="{ch["shorts"]}" stroke="{C["line"]}" stroke-width="{LW}" stroke-linejoin="round"/>'


def torso(ch, name):
    st, wb = ch["shoulder_y"], ch["waist_y"]
    tt, tb = ch["torso_top"] / 2, ch["torso_bot"] / 2
    bulge = 8 if name == "fofo" else 0
    d = (f"M{f(CX - tt)},{f(st + 10)} Q{f(CX - tt)},{f(st - 4)} {f(CX - tt + 14)},{f(st - 4)} "
         f"L{f(CX + tt - 14)},{f(st - 4)} Q{f(CX + tt)},{f(st - 4)} {f(CX + tt)},{f(st + 10)} "
         f"Q{f(CX + tb + bulge)},{f((st + wb) / 2 + 8)} {f(CX + tb)},{f(wb + 6)} "
         f"Q{f(CX)},{f(wb + 12)} {f(CX - tb)},{f(wb + 6)} "
         f"Q{f(CX - tb - bulge)},{f((st + wb) / 2 + 8)} {f(CX - tt)},{f(st + 10)} Z")
    s = f'<path d="{d}" fill="{ch["shirt"]}" stroke="{C["line"]}" stroke-width="{LW}" stroke-linejoin="round"/>'
    # neck + collar
    s += f'<rect x="{f(CX - 10)}" y="{f(st - 16)}" width="20" height="18" rx="6" fill="{C["skin_dark"]}"/>'
    s += f'<path d="M{f(CX - 16)},{f(st - 4)} Q{f(CX)},{f(st + 12)} {f(CX + 16)},{f(st - 4)}" fill="none" stroke="{ch["trim"]}" stroke-width="5" stroke-linecap="round"/>'
    if name == "nono":
        # lightning bolt: he never stops
        bx, by = CX + 4, st + 22
        s += (f'<path d="M{f(bx + 4)},{f(by - 12)} L{f(bx - 9)},{f(by + 3)} L{f(bx - 1)},{f(by + 3)} '
              f'L{f(bx - 5)},{f(by + 17)} L{f(bx + 10)},{f(by - 1)} L{f(bx + 2)},{f(by - 1)} Z" '
              f'fill="{C["yellow"]}" stroke="{C["line"]}" stroke-width="2.5" stroke-linejoin="round"/>')
        # side stripes
        for sx in (-1, 1):
            x = CX + sx * (tb - 6)
            s += f'<path d="M{f(x)},{f(st + 14)} L{f(x)},{f(wb + 2)}" stroke="{C["yellow"]}" stroke-width="4" stroke-linecap="round"/>'
    else:
        # pocket with a pencil: he likes to think things through
        px, py = CX + 14, st + 18
        s += f'<path d="M{f(px - 4)},{f(py + 2)} L{f(px + 1)},{f(py - 16)} L{f(px + 6)},{f(py + 2)}" fill="{C["yellow"]}" stroke="{C["line"]}" stroke-width="2.5" stroke-linejoin="round"/>'
        s += f'<rect x="{f(px - 10)}" y="{f(py)}" width="22" height="18" rx="4" fill="{C["green"]}" stroke="{C["line"]}" stroke-width="2.5"/>'
    return s


def hand(pts, kind, w):
    (ex, ey), (hx, hy) = pts[-2], pts[-1]
    r = w * 0.62
    ang = math.atan2(hy - ey, hx - ex)
    s = ""
    if kind == "point":
        tx, ty = hx + math.cos(ang) * (r + 9), hy + math.sin(ang) * (r + 9)
        s += poly_stroke([(hx, hy), (tx, ty)], 6, C["skin"])
    elif kind == "point_up":
        s += poly_stroke([(hx, hy), (hx, hy - r - 10)], 6, C["skin"])
    elif kind == "thumb":
        s += poly_stroke([(hx - 2, hy), (hx - 2, hy - r - 8)], 7, C["skin"])
    elif kind == "open":
        for da in (-0.7, 0, 0.7):
            a = ang + da
            s += poly_stroke([(hx, hy), (hx + math.cos(a) * (r + 6), hy + math.sin(a) * (r + 6))], 5.5, C["skin"])
    s += circle(hx, hy, r, C["skin"])
    return s


def arm(ch, side, spec):
    shoulder = (CX + side * ch["shoulder_dx"], ch["shoulder_y"] + 4)
    if spec[0] == "ik":
        pts = ik(shoulder, (spec[1], spec[2]), ch["arm"], side)
        kind = spec[3] if len(spec) > 3 else "fist"
    else:
        pts = from_angles(shoulder, side, ch["arm"], spec[:2])
        kind = spec[2] if len(spec) > 2 else "fist"
    s = poly_stroke(pts, ch["arm_w"], C["skin"])
    # short sleeve over the top half of the upper arm
    (sx, sy), (ex, ey) = pts[0], pts[1]
    s += poly_stroke([(sx, sy), (sx + (ex - sx) * 0.42, sy + (ey - sy) * 0.42)], ch["arm_w"] + 5, ch["shirt"])
    s += hand(pts, kind, ch["arm_w"])
    return s, pts[-1]


# ---------- head & face ----------
def hair_spiky(hx, hy, r):
    pts = []
    n = 9
    for i in range(n + 1):
        a = math.radians(200 - i * (220 / n))
        rr = r + (20 if i % 2 == 0 else -2) + (6 if i == n // 2 + 1 else 0)
        # spikes lean back like he's mid-run
        lean = 6 if i % 2 == 0 else 0
        pts.append((hx + rr * math.cos(a) + lean, hy - rr * math.sin(a)))
    # fringe zigzag from right to left over the forehead
    fr = []
    for i in range(7):
        x = hx + r * 0.92 - i * (r * 1.84 / 6)
        y = hy - r * (0.32 if i % 2 == 0 else 0.55)
        fr.append((x, y))
    allp = pts + fr
    d = "M" + " L".join(f"{f(x)},{f(y)}" for x, y in allp) + " Z"
    s = f'<path d="{d}" fill="{C["hair"]}" stroke="{C["line"]}" stroke-width="{LW}" stroke-linejoin="round"/>'
    # cowlick
    s += f'<path d="M{f(hx + 4)},{f(hy - r - 14)} q8,-22 22,-18" fill="none" stroke="{C["hair"]}" stroke-width="6" stroke-linecap="round"/>'
    return s


def hair_curly(hx, hy, r):
    s = ""
    cap = (f"M{f(hx - r * 0.98)},{f(hy - 2)} A{f(r)},{f(r)} 0 0 1 {f(hx + r * 0.98)},{f(hy - 2)} "
           f"L{f(hx + r * 0.8)},{f(hy - r * 0.42)} L{f(hx - r * 0.8)},{f(hy - r * 0.42)} Z")
    s += f'<path d="{cap}" fill="{C["hair"]}"/>'
    for i in range(11):
        a = math.radians(185 - i * 19)
        x, y = hx + r * 0.95 * math.cos(a), hy - r * 0.95 * math.sin(a)
        s += circle(x, y, 15, C["hair"])
    for i in range(5):
        x = hx - r * 0.62 + i * (r * 1.24 / 4)
        s += circle(x, hy - r * 0.5 + (3 if i % 2 else 0), 13, C["hair"])
    # curl highlights
    for i in range(4):
        x = hx - r * 0.45 + i * (r * 0.3)
        s += f'<path d="M{f(x - 4)},{f(hy - r * 0.78)} q4,-5 8,0" fill="none" stroke="#5A4030" stroke-width="2.2" stroke-linecap="round"/>'
    return s


def eye(x, y, kind, look=(0, 0)):
    lx, ly = look
    line = C["line"]
    if kind == "happy":
        return f'<path d="M{f(x - 8)},{f(y + 3)} Q{f(x)},{f(y - 9)} {f(x + 8)},{f(y + 3)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
    if kind == "closed":
        return f'<path d="M{f(x - 8)},{f(y)} Q{f(x)},{f(y + 7)} {f(x + 8)},{f(y)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
    if kind == "wide":
        return (circle(x, y, 10.5, C["white"], extra="")
                + circle(x + lx, y + ly, 5, line, stroke=False)
                + circle(x + lx - 1.5, y + ly - 2, 1.8, C["white"], stroke=False))
    if kind == "half":  # focused, looking down
        return (ellipse(x + lx, y + 2 + ly, 6.5, 7, line, stroke=False)
                + f'<path d="M{f(x - 9)},{f(y - 2)} L{f(x + 9)},{f(y - 2)}" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
                + f'<rect x="{f(x - 9)}" y="{f(y - 11)}" width="18" height="9" fill="{C["skin"]}"/>')
    return (ellipse(x + lx, y + ly, 6.5, 9, line, stroke=False)
            + circle(x + lx - 2, y + ly - 3.5, 2.4, C["white"], stroke=False))


def brow(x, y, side, kind):
    # side: -1 left eye, +1 right eye; inner end is toward the face center
    o, i = x + side * 9, x - side * 7
    if kind == "raised":
        return f'<path d="M{f(i)},{f(y - 5)} Q{f(x)},{f(y - 12)} {f(o)},{f(y - 5)}" fill="none" stroke="{C["hair"]}" stroke-width="4.5" stroke-linecap="round"/>'
    if kind == "worried":
        return f'<path d="M{f(i)},{f(y - 6)} L{f(o)},{f(y + 1)}" stroke="{C["hair"]}" stroke-width="4.5" stroke-linecap="round"/>'
    if kind == "determined":
        return f'<path d="M{f(i)},{f(y + 2)} L{f(o)},{f(y - 4)}" stroke="{C["hair"]}" stroke-width="4.5" stroke-linecap="round"/>'
    if kind == "think":  # one up, one flat
        if side > 0:
            return brow(x, y, side, "raised")
        return f'<path d="M{f(i)},{f(y)} L{f(o)},{f(y)}" stroke="{C["hair"]}" stroke-width="4.5" stroke-linecap="round"/>'
    return f'<path d="M{f(i)},{f(y)} Q{f(x)},{f(y - 5)} {f(o)},{f(y)}" fill="none" stroke="{C["hair"]}" stroke-width="4.5" stroke-linecap="round"/>'


def mouth(x, y, kind):
    line = C["line"]
    if kind == "grin":
        return (f'<path d="M{f(x - 15)},{f(y - 2)} Q{f(x)},{f(y + 24)} {f(x + 15)},{f(y - 2)} Z" fill="{line}" stroke="{line}" stroke-width="3" stroke-linejoin="round"/>'
                + f'<path d="M{f(x - 12)},{f(y)} L{f(x + 12)},{f(y)} L{f(x + 10)},{f(y + 4)} L{f(x - 10)},{f(y + 4)} Z" fill="{C["white"]}"/>'
                + ellipse(x, y + 12, 7, 4, C["coral"], stroke=False))
    if kind == "open":
        return (f'<path d="M{f(x - 10)},{f(y)} Q{f(x)},{f(y + 17)} {f(x + 10)},{f(y)} Z" fill="{line}" stroke="{line}" stroke-width="3" stroke-linejoin="round"/>'
                + ellipse(x, y + 8, 5, 3, C["coral"], stroke=False))
    if kind == "smile":
        return f'<path d="M{f(x - 11)},{f(y)} Q{f(x)},{f(y + 11)} {f(x + 11)},{f(y)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
    if kind == "small":
        return f'<path d="M{f(x - 6)},{f(y + 1)} Q{f(x)},{f(y + 6)} {f(x + 6)},{f(y + 1)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
    if kind == "o":
        return ellipse(x, y + 4, 6, 8, line, stroke=False) + ellipse(x, y + 8, 3.5, 2.5, C["coral"], stroke=False)
    if kind == "frown":
        return f'<path d="M{f(x - 9)},{f(y + 6)} Q{f(x)},{f(y - 2)} {f(x + 9)},{f(y + 6)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
    if kind == "wobbly":
        return f'<path d="M{f(x - 12)},{f(y + 4)} l6,-4 l6,4 l6,-4 l6,4" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
    if kind == "hmm":
        return f'<path d="M{f(x - 6)},{f(y + 4)} Q{f(x + 2)},{f(y + 6)} {f(x + 10)},{f(y)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
    if kind == "tongue":
        return (f'<path d="M{f(x - 11)},{f(y)} Q{f(x)},{f(y + 10)} {f(x + 11)},{f(y)}" fill="none" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'
                + f'<path d="M{f(x + 3)},{f(y + 5)} q4,10 10,4 q-1,-4 -3,-6" fill="{C["coral"]}" stroke="{line}" stroke-width="2.5" stroke-linejoin="round"/>')
    if kind == "drool":
        return (ellipse(x, y + 3, 5, 4, line, stroke=False)
                + f'<path d="M{f(x + 4)},{f(y + 6)} q2,8 0,10" fill="none" stroke="{C["seafoam"]}" stroke-width="3" stroke-linecap="round"/>')
    return f'<path d="M{f(x - 8)},{f(y + 2)} L{f(x + 8)},{f(y + 2)}" stroke="{line}" stroke-width="4" stroke-linecap="round"/>'


def head(ch, pose):
    r, hx, hy = ch["head_r"], CX, ch["head_y"]
    s = ""
    # ears
    for side in (-1, 1):
        s += circle(hx + side * (r - 3), hy + 8, 11, C["skin"])
        s += f'<path d="M{f(hx + side * (r - 1))},{f(hy + 3)} q{f(side * 4)},5 0,10" fill="none" stroke="{C["skin_dark"]}" stroke-width="2.5" stroke-linecap="round"/>'
    s += circle(hx, hy, r, C["skin"])
    s += hair_spiky(hx, hy, r) if ch["hair"] == "spiky" else hair_curly(hx, hy, r)
    ey = hy + 8
    ex = 21
    look = pose.get("look", (0, 0))
    eyes = pose.get("eyes", "open")
    for side in (-1, 1):
        s += eye(hx + side * ex, ey, eyes, look)
    # cheeks + nose
    s += ellipse(hx - 35, hy + 26, 9, 5.5, C["blush"], stroke=False, extra=' opacity="0.55"')
    s += ellipse(hx + 35, hy + 26, 9, 5.5, C["blush"], stroke=False, extra=' opacity="0.55"')
    s += f'<path d="M{f(hx - 3)},{f(hy + 19)} Q{f(hx)},{f(hy + 23)} {f(hx + 3)},{f(hy + 19)}" fill="none" stroke="{C["skin_dark"]}" stroke-width="3" stroke-linecap="round"/>'
    by = ey - 16
    if ch["glasses"]:
        g = C["coral"]
        for side in (-1, 1):
            s += f'<circle cx="{f(hx + side * ex)}" cy="{f(ey)}" r="15" fill="{C["white"]}" fill-opacity="0.22" stroke="{g}" stroke-width="4"/>'
        s += f'<path d="M{f(hx - 6)},{f(ey - 2)} Q{f(hx)},{f(ey - 7)} {f(hx + 6)},{f(ey - 2)}" fill="none" stroke="{g}" stroke-width="4" stroke-linecap="round"/>'
        s += f'<path d="M{f(hx - ex - 8)},{f(ey - 9)} l6,-3" stroke="{C["white"]}" stroke-width="2.5" stroke-linecap="round" opacity="0.8"/>'
        by = ey - 22
    for side in (-1, 1):
        s += brow(hx + side * ex, by, side, pose.get("brows", "normal"))
    s += mouth(hx, hy + 32, pose.get("mouth", "smile"))
    tilt = pose.get("tilt", 0)
    if tilt:
        s = f'<g transform="rotate({f(tilt)} {f(CX)} {f(ch["shoulder_y"] - 6)})">{s}</g>'
    return s


# ---------- props ----------
def prop(name, ch, geo):
    hx, hy, r = CX, ch["head_y"], ch["head_r"]
    line = C["line"]
    if name == "confetti":
        s = ""
        bits = [(-110, -40, C["yellow"], 0), (105, -55, C["coral"], 20), (-95, 40, C["green"], 10),
                (115, 30, C["yellow"], 35), (-60, -95, C["seafoam"], 5), (70, -100, C["green"], 15)]
        for dx, dy, col, rot in bits:
            s += star(hx + dx, hy + dy, 11, col, rot)
        for dx, dy, col in [(-120, 0, C["coral"]), (125, -10, C["seafoam"]), (-40, -110, C["coral"]), (40, -115, C["yellow"])]:
            s += f'<rect x="{f(hx + dx)}" y="{f(hy + dy)}" width="9" height="5" rx="1.5" fill="{col}" transform="rotate(30 {f(hx + dx)} {f(hy + dy)})"/>'
        return s
    if name == "sparkles":
        return star(hx - 100, hy - 30, 10, C["yellow"]) + star(hx + 100, hy - 45, 13, C["yellow"], 15) + star(hx + 85, hy + 30, 8, C["coral"])
    if name == "sweat":
        x, y = hx - r + 6, hy - 22
        return f'<path d="M{f(x)},{f(y)} q-9,14 0,18 q9,-4 0,-18 Z" fill="{C["seafoam"]}" stroke="{line}" stroke-width="2.5" stroke-linejoin="round"/>'
    if name == "bulb":
        x, y = hx + r + 14, hy - r - 6
        s = ""
        for a in range(-150, -20, 30):
            ra = math.radians(a)
            s += f'<path d="M{f(x + 22 * math.cos(ra))},{f(y + 22 * math.sin(ra))} L{f(x + 31 * math.cos(ra))},{f(y + 31 * math.sin(ra))}" stroke="{C["yellow"]}" stroke-width="4" stroke-linecap="round"/>'
        s += circle(x, y, 16, C["yellow"])
        s += f'<rect x="{f(x - 8)}" y="{f(y + 13)}" width="16" height="12" rx="3" fill="{C["mist"]}" stroke="{line}" stroke-width="3"/>'
        s += f'<path d="M{f(x - 5)},{f(y + 2)} q5,-8 10,0" fill="none" stroke="{C["white"]}" stroke-width="3" stroke-linecap="round"/>'
        return s
    if name == "question":
        x, y = hx + r + 18, hy - r + 4
        return (f'<path d="M{f(x - 9)},{f(y - 8)} q0,-14 12,-13 q13,2 10,15 q-2,7 -10,10 l0,8" fill="none" stroke="{C["coral"]}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>'
                + circle(x + 3, y + 22, 4.5, C["coral"], stroke=False))
    if name == "exclaim":
        s = ""
        for dx, rot in ((-r - 26, -15), (r + 26, 15)):
            x, y = hx + dx, hy - r + 8
            s += f'<g transform="rotate({rot} {f(x)} {f(y)})"><rect x="{f(x - 4.5)}" y="{f(y - 22)}" width="9" height="24" rx="4.5" fill="{C["coral"]}"/>{circle(x, y + 10, 5, C["coral"], stroke=False)}</g>'
        return s
    if name == "zzz":
        s = ""
        for i, (dx, dy, sz) in enumerate(((r + 4, -r + 20, 14), (r + 24, -r - 6, 18), (r + 48, -r - 38, 23))):
            x, y = hx + dx, hy + dy
            s += f'<path d="M{f(x)},{f(y)} L{f(x + sz)},{f(y)} L{f(x)},{f(y + sz)} L{f(x + sz)},{f(y + sz)}" fill="none" stroke="{C["mist"]}" stroke-width="{4 + i}" stroke-linecap="round" stroke-linejoin="round"/>'
        return s
    if name == "thought":
        x, y = hx + r + 6, hy - r + 2
        return (circle(x - 4, y + 14, 4, C["white"]) + circle(x + 8, y - 2, 6.5, C["white"])
                + circle(x + 26, y - 22, 10, C["white"]))
    if name == "wave_lines":
        x, y = geo["hand_R"]
        s = ""
        for i, rr in enumerate((22, 32)):
            s += f'<path d="M{f(x + rr * 0.5)},{f(y - rr * 0.85)} A{rr},{rr} 0 0 1 {f(x + rr)},{f(y)}" fill="none" stroke="{C["mist"]}" stroke-width="3.5" stroke-linecap="round"/>'
        return s
    if name == "speed":
        s = ""
        for i, (y, L) in enumerate(((ch["shoulder_y"] - 10, 60), (ch["shoulder_y"] + 25, 80), (ch["hip_y"], 55), (ch["head_y"] - 10, 45))):
            x = CX - 75 - i * 6
            s += f'<path d="M{f(x)},{f(y)} L{f(x - L)},{f(y)}" stroke="{C["mist"]}" stroke-width="5" stroke-linecap="round" opacity="0.7"/>'
        return s
    if name == "dust":
        return (circle(CX - 60, GROUND - 6, 10, C["sand"]) + circle(CX - 78, GROUND - 12, 7, C["sand"])
                + circle(CX - 92, GROUND - 4, 5, C["sand"]))
    if name == "bounce":
        return (f'<path d="M{f(CX - 40)},{f(GROUND + 2)} l-10,4 M{f(CX + 40)},{f(GROUND + 2)} l10,4" stroke="{C["mist"]}" stroke-width="3.5" stroke-linecap="round"/>')
    if name == "book":
        bx, by = CX, ch["waist_y"] - 14
        w2, hgt = 50, 38
        return (f'<path d="M{f(bx - w2)},{f(by - hgt / 2 + 4)} Q{f(bx - w2 / 2)},{f(by - hgt / 2 - 4)} {f(bx)},{f(by - hgt / 2 + 4)} Q{f(bx + w2 / 2)},{f(by - hgt / 2 - 4)} {f(bx + w2)},{f(by - hgt / 2 + 4)} '
                f'L{f(bx + w2)},{f(by + hgt / 2 + 4)} Q{f(bx + w2 / 2)},{f(by + hgt / 2 - 4)} {f(bx)},{f(by + hgt / 2 + 4)} Q{f(bx - w2 / 2)},{f(by + hgt / 2 - 4)} {f(bx - w2)},{f(by + hgt / 2 + 4)} Z" '
                f'fill="{C["coral"]}" stroke="{line}" stroke-width="{LW}" stroke-linejoin="round"/>'
                + f'<path d="M{f(bx - w2 + 5)},{f(by - hgt / 2 + 2)} Q{f(bx - w2 / 2)},{f(by - hgt / 2 - 5)} {f(bx)},{f(by - hgt / 2 + 3)} L{f(bx)},{f(by + hgt / 2)} Q{f(bx - w2 / 2)},{f(by + hgt / 2 - 8)} {f(bx - w2 + 5)},{f(by + hgt / 2 - 1)} Z" fill="{C["white"]}" stroke="{line}" stroke-width="2"/>'
                + f'<path d="M{f(bx + w2 - 5)},{f(by - hgt / 2 + 2)} Q{f(bx + w2 / 2)},{f(by - hgt / 2 - 5)} {f(bx)},{f(by - hgt / 2 + 3)} L{f(bx)},{f(by + hgt / 2)} Q{f(bx + w2 / 2)},{f(by + hgt / 2 - 8)} {f(bx + w2 - 5)},{f(by + hgt / 2 - 1)} Z" fill="{C["white"]}" stroke="{line}" stroke-width="2"/>'
                # a big Coptic-alpha-like squiggle on the left page, lines on the right
                + f'<path d="M{f(bx - 18)},{f(by - 4)} q-10,-2 -10,8 q2,8 10,2 q3,-6 3,-12 l3,14" fill="none" stroke="{C["teal"]}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
                + "".join(f'<path d="M{f(bx + 8)},{f(by - 8 + i * 7)} L{f(bx + w2 - 12)},{f(by - 8 + i * 7)}" stroke="{C["mist"]}" stroke-width="2.5" stroke-linecap="round"/>' for i in range(3)))
    if name == "slate":
        bx, by = CX - 4, ch["waist_y"] - 12
        return (f'<rect x="{f(bx - 40)}" y="{f(by - 26)}" width="80" height="52" rx="8" fill="{C["drift"]}" stroke="{line}" stroke-width="{LW}"/>'
                + f'<rect x="{f(bx - 33)}" y="{f(by - 19)}" width="66" height="38" rx="4" fill="{C["teal"]}"/>'
                + f'<path d="M{f(bx - 18)},{f(by - 2)} q-10,-2 -10,8 q2,8 10,2 q3,-6 3,-12 l3,14" fill="none" stroke="{C["white"]}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
                + f'<path d="M{f(bx + 4)},{f(by - 8)} q8,-6 14,0 q-6,6 0,12 q8,4 12,-2" fill="none" stroke="{C["white"]}" stroke-width="3" stroke-linecap="round" stroke-dasharray="4 4"/>')
    if name == "pencil":
        x, y = geo["hand_R"]
        return (f'<g transform="rotate(35 {f(x)} {f(y)})">'
                f'<rect x="{f(x - 5)}" y="{f(y - 30)}" width="10" height="34" rx="2" fill="{C["yellow"]}" stroke="{line}" stroke-width="2.5"/>'
                f'<rect x="{f(x - 5)}" y="{f(y - 36)}" width="10" height="8" rx="3" fill="{C["coral"]}" stroke="{line}" stroke-width="2.5"/>'
                f'<path d="M{f(x - 5)},{f(y + 4)} L{f(x)},{f(y + 14)} L{f(x + 5)},{f(y + 4)} Z" fill="{C["sand"]}" stroke="{line}" stroke-width="2.5" stroke-linejoin="round"/></g>')
    return ""


# ---------- poses ----------
# arm spec: (upper_deg, lower_deg, hand) or ("ik", x, y, hand). "front" arms draw over the head.
# leg spec: (upper_deg, lower_deg)
def nono_poses(ch):
    hy, r, sy = ch["head_y"], ch["head_r"], ch["shoulder_y"]
    straight = {"L": (5, 2), "R": (5, 2)}
    return {
        "idle": dict(dy=-6, arms={"L": (14, 8), "R": (14, 8)}, legs={"L": (6, 0), "R": (6, 0)},
                     eyes="open", brows="normal", mouth="grin", props_front=["bounce"]),
        "cheer": dict(arms={"L": (150, 168, "fist"), "R": (150, 168, "fist")}, legs={"L": (10, 2), "R": (10, 2)},
                      eyes="happy", brows="raised", mouth="grin", props_front=["sparkles"]),
        "wrong": dict(arms={"L": (6, 0), "R": ("ik", CX + r - 2, hy - 18, "open")}, front=["R"],
                      legs={"L": (4, 0), "R": (8, -6)}, tilt=-6, eyes="wide", look=(-2, 0),
                      brows="worried", mouth="wobbly", props_front=["sweat"]),
        "hint": dict(arms={"L": (40, -50), "R": (82, 92, "point")}, legs=straight, look=(3, 0),
                     eyes="open", brows="think", mouth="grin", tilt=4),
        "celebrate": dict(dy=-42, arms={"L": (140, 155, "open"), "R": (140, 155, "open")},
                          legs={"L": (35, 10), "R": (35, 10)}, eyes="happy", brows="raised", mouth="grin",
                          props_back=["confetti"], shadow=0.6),
        "encourage": dict(arms={"L": (45, -55), "R": (40, 165, "thumb")}, legs={"L": (8, 0), "R": (8, 0)},
                          eyes="happy", brows="normal", mouth="smile", tilt=-4, props_front=["sparkles"]),
        "run": dict(dy=-14, lean=9, arms={"L": (35, -60), "R": (25, 140)},
                    legs={"L": (10, 25), "R": (60, -40)}, eyes="open", look=(3, 0), brows="determined",
                    mouth="grin", props_back=["speed"], props_ground=["dust"], shadow=0.8),
        "wave": dict(arms={"L": (6, 0), "R": (125, 168, "open")}, legs=straight, eyes="open",
                     brows="raised", mouth="grin", tilt=-5, props_front=["wave_lines"]),
        "write": dict(arms={"L": ("ik", CX - 38, sy + 46), "R": ("ik", CX + 14, sy + 46)}, legs=straight,
                      eyes="half", look=(-1, 1), brows="determined", mouth="tongue", tilt=6,
                      props_mid=["slate"], props_front=["pencil"]),
        "read": dict(arms={"L": ("ik", CX - 50, sy + 44), "R": ("ik", CX + 50, sy + 44)}, legs=straight,
                     eyes="half", look=(0, 1), brows="raised", mouth="o", tilt=-3, props_mid=["book"]),
        "sleep": dict(dy=51, arms={"L": (25, 10, "open"), "R": (25, 10, "open")},
                      legs={"L": (95, 20), "R": (95, 20)}, eyes="closed", brows="normal", mouth="drool",
                      tilt=14, props_front=["zzz"]),
        "surprised": dict(dy=-10, arms={"L": (120, 150, "open"), "R": (120, 150, "open")},
                          legs={"L": (14, -4), "R": (14, -4)}, eyes="wide", brows="raised", mouth="o",
                          props_front=["exclaim"]),
    }


def fofo_poses(ch):
    hy, r, sy = ch["head_y"], ch["head_r"], ch["shoulder_y"]
    straight = {"L": (4, 0), "R": (4, 0)}
    return {
        "idle": dict(arms={"L": ("ik", CX - 12, sy + 34), "R": ("ik", CX + 14, hy + r - 2)}, front=["R"],
                     legs=straight, eyes="open", look=(2, -3), brows="think", mouth="hmm",
                     props_front=["thought"]),
        "cheer": dict(arms={"L": (150, 165, "fist"), "R": (150, 165, "fist")}, legs={"L": (8, 0), "R": (8, 0)},
                      eyes="happy", brows="raised", mouth="open", props_front=["sparkles"]),
        "wrong": dict(arms={"L": ("ik", CX - 6, sy + 40), "R": ("ik", CX + 6, sy + 40)}, legs=straight,
                      eyes="open", look=(0, 2), brows="worried", mouth="frown", tilt=6,
                      props_front=["question"]),
        "hint": dict(arms={"L": (8, 0), "R": ("ik", CX + 68, hy + 10, "point_up")}, legs=straight,
                     eyes="open", look=(2, -2), brows="raised", mouth="smile", props_front=["bulb"]),
        "celebrate": dict(dy=-34, arms={"L": (140, 160, "open"), "R": (140, 160, "open")},
                          legs={"L": (30, -5), "R": (30, -5)}, eyes="happy", brows="raised", mouth="open",
                          props_back=["confetti"], shadow=0.65),
        "encourage": dict(arms={"L": (10, 0), "R": (45, 160, "thumb")}, legs=straight,
                          eyes="happy", brows="normal", mouth="smile", tilt=5),
        "run": dict(dy=-8, lean=6, arms={"L": (40, -70), "R": (30, 130)},
                    legs={"L": (8, 20), "R": (55, -40)}, eyes="open", look=(2, 0), brows="determined",
                    mouth="open", props_back=["speed"], props_ground=["dust"], shadow=0.85),
        "wave": dict(arms={"L": (8, 0), "R": (125, 165, "open")}, legs=straight, eyes="open",
                     brows="raised", mouth="smile", tilt=-5, props_front=["wave_lines"]),
        "write": dict(arms={"L": ("ik", CX - 38, sy + 44), "R": ("ik", CX + 12, sy + 44)}, legs=straight,
                      eyes="half", look=(-1, 1), brows="normal", mouth="small", tilt=5,
                      props_mid=["slate"], props_front=["pencil"]),
        "read": dict(arms={"L": ("ik", CX - 50, sy + 46), "R": ("ik", CX + 50, sy + 46)}, legs=straight,
                     eyes="half", look=(0, 1), brows="normal", mouth="smile", tilt=-3, props_mid=["book"]),
        "sleep": dict(dy=27, arms={"L": (25, 10, "open"), "R": (25, 10, "open")},
                      legs={"L": (95, 20), "R": (95, 20)}, eyes="closed", brows="normal", mouth="small",
                      tilt=-12, props_front=["zzz"]),
        "surprised": dict(dy=-6, arms={"L": ("ik", CX - r + 6, hy + 34, "open"), "R": ("ik", CX + r - 6, hy + 34, "open")},
                          front=["L", "R"], legs={"L": (10, -2), "R": (10, -2)}, eyes="wide", brows="raised",
                          mouth="o", props_front=["exclaim"]),
    }


POSE_ORDER = ["idle", "cheer", "wrong", "hint", "celebrate", "encourage",
              "run", "wave", "write", "read", "sleep", "surprised"]


def render(name, pose_name, pose):
    ch = CHARS[name]
    dy, lean = pose.get("dy", 0), pose.get("lean", 0)
    geo = {}
    legs = "".join(leg(ch, s, pose["legs"]["L" if s < 0 else "R"]) for s in (-1, 1))
    arm_svgs = {}
    for key, side in (("L", -1), ("R", 1)):
        svg, hand_pt = arm(ch, side, pose["arms"][key])
        arm_svgs[key] = svg
        geo["hand_" + key] = hand_pt
    front = pose.get("front", [])
    body = ""
    body += "".join(prop(p, ch, geo) for p in pose.get("props_back", []))
    body += legs + shorts(ch) + torso(ch, name)
    body += "".join(prop(p, ch, geo) for p in pose.get("props_mid", []))
    body += "".join(v for k, v in arm_svgs.items() if k not in front)
    body += head(ch, pose)
    body += "".join(v for k, v in arm_svgs.items() if k in front)
    body += "".join(prop(p, ch, geo) for p in pose.get("props_front", []))
    shadow_scale = pose.get("shadow", 1)
    ground = "".join(prop(p, ch, geo) for p in pose.get("props_ground", []))
    shadow = f'<ellipse cx="{CX}" cy="{GROUND + 6}" rx="{f(58 * shadow_scale)}" ry="{f(9 * shadow_scale)}" fill="{C["line"]}" opacity="0.14"/>'
    tr = f"translate(0 {f(dy)})"
    if lean:
        tr += f" rotate({f(lean)} {CX} {GROUND})"
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">'
            f'<title>{name} {pose_name}</title>'
            f'{shadow}{ground}<g id="body" transform="{tr}">{body}</g></svg>')


def main():
    pose_sets = {"nono": nono_poses(CHARS["nono"]), "fofo": fofo_poses(CHARS["fofo"])}
    for name, poses in pose_sets.items():
        for pn in POSE_ORDER:
            path = os.path.join(OUT, name, f"{pn}.svg")
            with open(path, "w") as fh:
                fh.write(render(name, pn, poses[pn]))
    print(f"wrote {len(POSE_ORDER) * 2} SVGs to {OUT}")


if __name__ == "__main__":
    main()
