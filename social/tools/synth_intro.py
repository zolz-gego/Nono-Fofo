#!/usr/bin/env python3
"""Logo intro score ("Grandpa's Pop-up Book"), composed entirely in code.

Reads social/remotion/src/intro/cues.json, the same timeline the picture uses,
so every pop-up fold, page turn and hit lands on the same sample.
120 BPM in D hijaz (D Eb F# G A Bb C): Grandpa's clock, the lamp, a qanun
motif, creaking cover, paper pops, Nile water, desert wind, pigeons, page
turns, the alphabet rising, and the final drop.

Run:  tools/.venv/bin/python social/tools/synth_intro.py
Out:  social/assets/music/intro_logo_book.wav (44.1 kHz stereo 16-bit)
      social/assets/manifest.json ("music" section)
"""
import json
import os
import sys
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "audio"))

from dsp import (SR, bell, boing, chime, doum, glass, hz, impulses, marimba, n_of, noise, osc, perc,  # noqa: E402
                 pluck, pop, slide_whistle, sparkle, svf, sweep, tek, thud, tt, water, whoosh, wood)

INTRO = os.path.join(ROOT, "social", "remotion", "src", "intro")
CUES = json.load(open(os.path.join(INTRO, "cues.json")))
OUT_ID = "intro_logo_book"
OUT_WAV = os.path.join(ROOT, "social", "assets", "music", f"{OUT_ID}.wav")
MANIFEST = os.path.join(ROOT, "social", "assets", "manifest.json")

BEAT = 60 / CUES["bpm"]
BAR = BEAT * 4
EIGHTH = BEAT / 2
SIXTEENTH = BEAT / 4


# ================================================================ stereo bus

class Bus:
    def __init__(self, dur):
        self.L = np.zeros(n_of(dur))
        self.R = np.zeros(n_of(dur))
        self.send = np.zeros(n_of(dur))   # reverb send (mono)

    def add(self, sig, at, gain=1.0, pan=0.0, verb=0.0):
        s = int(round(at * SR))
        if s >= len(self.L):
            return
        sig = sig[: len(self.L) - s]
        e = s + len(sig)
        th = (pan + 1) * np.pi / 4                         # constant-power pan
        self.L[s:e] += gain * np.cos(th) * sig
        self.R[s:e] += gain * np.sin(th) * sig
        if verb:
            self.send[s:e] += gain * verb * sig


def hall(x, seconds=2.4, tau=0.55, seed=3):
    """Long, soft stereo hall (two decorrelated noise IRs)."""
    rng = np.random.default_rng(seed)
    outs = []
    for ch in range(2):
        ir = rng.uniform(-1, 1, n_of(seconds)) * np.exp(-tt(seconds) / tau)
        ir = svf(ir, 4500, mode="lp")
        ir[: n_of(0.012 + 0.007 * ch)] = 0                 # pre-delay
        ir /= np.sqrt(np.sum(ir ** 2))
        size = 1 << (len(x) + len(ir)).bit_length()
        y = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
        outs.append(y)
    return outs


# ================================================================ instruments

def note(name, semis=0):
    return hz(name) * 2 ** (semis / 12)


def saw_pad(notes, d, cutoff=1400, a=0.4, r=0.6):
    x = sum(osc(hz(n) * det, d, "saw") for n in notes for det in (0.997, 1.003))
    x = svf(x / len(notes), cutoff, q=0.6, mode="lp")
    env = np.ones(n_of(d))
    na, nr = n_of(a), n_of(r)
    env[:na] = np.linspace(0, 1, na)
    env[-nr:] *= np.linspace(1, 0, nr)
    return x * env


def bass(n, d=0.45):
    f = hz(n)
    body = osc(f, d, "tri") * perc(d, 0.004, 0.22) + 0.6 * osc(f / 2, d) * perc(d, 0.004, 0.3)
    return np.tanh(1.6 * body)


def shaker(d=0.07):
    return svf(noise(d), 7000, q=0.8, mode="hp") * perc(d, 0.006, 0.02)


def ka(d=0.08):
    return 0.6 * svf(noise(d), 5200, q=2.5, mode="bp") * perc(d, 0.0005, 0.012)


def boom(d=2.2):
    t = tt(d)
    sub = osc(sweep(95, 34, d, "fast"), d) * np.exp(-t / 0.7)
    crack = svf(noise(d), 900, mode="lp") * perc(d, 0.001, 0.06)
    return np.tanh(1.4 * (sub + 0.7 * crack))


def riser(d, f0=300, f1=6000):
    t = tt(d)
    env = (t / d) ** 2.2
    air = svf(noise(d), sweep(f0, f1, d), q=2.2, mode="bp") * 2.2
    tonal = osc(sweep(note("D3"), note("D5"), d), d, "saw") * 0.12
    return (air + svf(tonal, 2500, mode="lp")) * env


def swell(d):
    """Reverse-cymbal style swell that slams into the next hit."""
    t = tt(d)
    return svf(noise(d), 5000, q=0.7, mode="hp") * (t / d) ** 3


def glint():
    """Tiny metallic 'ting' for a light glint."""
    return glass(note("A7"), 0.5, tau=0.09) * 0.6


# ================================================================ score

SCALE = ["D4", "Eb4", "F#4", "G4", "A4", "Bb4", "C5", "D5", "Eb5", "F#5", "G5", "A5", "Bb5", "C6", "D6", "Eb6", "F#6"]
CHORDS = {
    "D": ["D3", "F#3", "A3", "D4"],
    "Gm": ["G3", "Bb3", "D4", "G4"],
    "Cm": ["C3", "Eb3", "G3", "C4"],
    "Eb": ["Eb3", "G3", "Bb3", "Eb4"],
}
ROOTS = {"D": "D2", "Gm": "G2", "Cm": "C2", "Eb": "Eb2"}
FIFTHS = {"D": "A2", "Gm": "D3", "Cm": "G2", "Eb": "Bb2"}
ARP = {"D": ["D5", "F#5", "A5", "D6"], "Gm": ["G4", "Bb4", "D5", "G5"], "Cm": ["C5", "Eb5", "G5", "C6"], "Eb": ["Eb5", "G5", "Bb5", "Eb6"]}
PROGRESSION = [(4, "D"), (6, "Gm"), (8, "Cm"), (10, "D"), (12, "Eb"), (14, "D"), (16, "Gm"), (18, "D")]
MAQSUM = [("D", 0), ("T", 1), ("T", 3), ("D", 4), ("T", 6)]


def chord_at(t):
    name = "D"
    for start, c in PROGRESSION:
        if t >= start:
            name = c
    return name


def paper_pop(f=520):
    """A pop-up piece springs open: paper 'fwip' + soft pop."""
    d = 0.12
    fwip = svf(noise(d), sweep(1200, 4200, d), q=1.6, mode="bp") * perc(d, 0.01, 0.035) * 1.6
    p = pop(f, 0.09)
    fwip[: len(p)] += 0.6 * p
    return fwip


def page_turn(d):
    """Paper swish with flutter, brightest in the middle of the turn."""
    t = tt(d)
    flutter = 0.6 + 0.4 * np.abs(np.sin(2 * np.pi * 14 * t))
    body = svf(noise(d), sweep(900, 3200, d), q=0.9, mode="bp") * np.sin(np.pi * t / d) ** 1.5 * flutter
    return body * 1.6


def creak(d):
    clicks = impulses(d, 40, 9, jitter=0.15)
    return svf(clicks, 850, q=6, mode="bp") * 3 + 0.3 * svf(clicks, 2400, q=4, mode="bp")


def coo(f=340):
    """Pigeon 'roo-coo': two soft vibrato hoots."""
    out = np.zeros(n_of(0.62))
    for at, d, ff in ((0.0, 0.18, f), (0.24, 0.36, f * 0.92)):
        x = osc(ff * (1 + 0.04 * np.sin(2 * np.pi * 9 * tt(d))), d) * np.sin(np.pi * tt(d) / d) ** 2
        s = n_of(at)
        out[s:s + len(x)] += x
    return svf(out, 900, mode="lp") * 1.4


def score():
    q = CUES
    dur = q["duration"]
    bus = Bus(dur + 0.5)

    # ---------------------------------------------------- the dark study
    for t in np.arange(0.0, q["cover"][0], 1.0):            # Grandpa's clock
        bus.add(wood(2400, 0.06), t + 0.1, 0.12, 0.6, 0.4)
        bus.add(wood(1800, 0.06), t + 0.6, 0.09, 0.6, 0.4)
    on = q["lampOn"]
    bus.add(wood(3000, 0.05), on, 0.45, -0.3)                         # switch click
    bus.add(thud(120, 0.08), on, 0.3, -0.3)
    hum = osc(60, dur - on) * 0.4 + osc(120, dur - on) * 0.15
    hum *= np.minimum(1, tt(dur - on) / 0.3)
    bus.add(hum * np.exp(-tt(dur - on) / 6.0), on, 0.04)
    bus.add(saw_pad(["D2", "A2", "D3"], q["cover"][1] + 0.5, cutoff=500, a=1.0, r=0.6), on, 0.28, 0, 0.4)
    for j, n in enumerate(["D5", "F#5", "A5", "G5", "F#5", "Eb5", "D5"]):  # qanun motif
        bus.add(pluck(n, 1.2, bright=0.6), 1.0 + j * 0.2, 0.28, -0.3 + j * 0.1, 0.6)

    # ---------------------------------------------------- the cover opens
    c0, c1 = q["cover"]
    bus.add(creak(c1 - c0), c0, 0.25, -0.2, 0.3)
    bus.add(whoosh(c1 - c0, 300, 1800, q=0.8), c0, 0.35, -0.4, 0.3)
    bus.add(thud(70, 0.4), c1, 0.6, -0.4, 0.2)
    bus.add(sparkle(1.2, 14, gain=0.3), c1 - 0.2, 0.6, 0, 0.6)
    for n, p in (("D5", -0.3), ("A5", 0.0), ("D6", 0.3)):
        bus.add(bell(n, 2.0, tau=0.7, ratio=2.0, index=0.9), c1, 0.2, p, 0.8)

    # ---------------------------------------------------- the groove under the pages
    g0, g1 = 4.0, q["card"][0]
    for bar in np.arange(g0, g1, BAR):
        light = bar < 8.0
        c = chord_at(bar)
        for kind, slot in MAQSUM:
            at = bar + slot * EIGHTH
            if at >= g1:
                continue
            if kind == "D":
                bus.add(doum(), at, 0.7)
            elif not light:
                bus.add(tek(), at, 0.35, 0.25)
        for s in range(16):
            at = bar + s * SIXTEENTH
            if at >= g1:
                continue
            bus.add(shaker(), at, 0.12 if s % 2 else 0.18, 0.45)
            if s % 2 == 0:
                bus.add(pluck(ARP[c][(s // 2) % 4], 0.6, bright=0.5), at, 0.1, -0.5 if s % 4 else 0.5, 0.4)
        pat = [(0, ROOTS[c], 1.0), (3, FIFTHS[c], 0.7), (4, ROOTS[c], 0.9), (7, note(ROOTS[c], 12), 0.6)]
        for slot, n, g in pat:
            at = bar + slot * EIGHTH
            if at < g1:
                bus.add(bass(n), at, 0.45 * g)
        bus.add(saw_pad(CHORDS[c], min(BAR, g1 - bar) + 0.3, cutoff=1100, a=0.25, r=0.4), bar, 0.13, 0, 0.5)

    # ---------------------------------------------------- pop-up pieces and page turns
    for si, sp in enumerate(q["spreads"]):
        for k, p in enumerate(sp["pieces"]):
            pan = max(-0.8, min(0.8, p["x"] / 90))
            if p["kind"] in ("nono", "fofo"):
                bus.add(paper_pop(600), p["at"], 0.45, pan)
                bus.add(boing(150 if p["kind"] == "nono" else 220, 380 if p["kind"] == "nono" else 520, 0.45), p["at"] + 0.05, 0.45, pan, 0.3)
            else:
                bus.add(paper_pop(420 + 60 * k), p["at"], 0.5, pan, 0.15)
                bus.add(marimba(SCALE[4 + si * 2 + k], 0.5), p["at"], 0.22, pan, 0.3)
            if "sail" in p:
                s0, s1, _ = p["sail"]
                for w in np.arange(s0, s1, 0.55):
                    bus.add(water(0.5, 1800), w, 0.14, -0.3 + 0.6 * (w - s0) / (s1 - s0), 0.4)
            if p["kind"] == "sun":
                bus.add(slide_whistle(600, 1300, 0.8, vib=0.004), p["at"] + 0.2, 0.06, 0.4, 0.5)
                bus.add(chime("A6", 1.4), p["at"] + 1.0, 0.3, 0.4, 0.6)
                bus.add(sparkle(0.8, 8), p["at"] + 1.0, 0.45, 0.4, 0.6)
    t0 = q["spreads"][1]["pieces"][1]["at"]                   # desert wind under the pyramids
    gust = svf(noise(2.4), sweep(300, 900, 2.4), q=1.2, mode="bp") * np.sin(np.pi * tt(2.4) / 2.4) ** 2 * 1.5
    bus.add(gust, t0 - 0.2, 0.25, 0.2, 0.3)
    v = q["spreads"][2]["pieces"]                             # pigeons over the village
    for at, pan in ((v[1]["at"] + 0.3, 0.6), (v[5]["at"] + 0.6, 0.5), (v[5]["at"] + 1.4, 0.7)):
        bus.add(coo(330 + 20 * pan), at, 0.3, pan, 0.4)
    kid = v[5]["at"] + 0.3                                    # ta-da when both brothers are up
    bus.add(marimba("G5", 0.3), kid, 0.3)
    bus.add(marimba("C6", 0.8), kid + 0.13, 0.3, 0, 0.3)
    bus.add(bell("C7", 1.0, tau=0.35, ratio=2.0, index=1.2), kid + 0.13, 0.14, 0, 0.5)
    for a, b in q["turns"]:
        bus.add(page_turn(b - a), a, 0.55, 0.0, 0.25)
        bus.add(thud(90, 0.2), b, 0.3, -0.3)

    # ---------------------------------------------------- the alphabet rises into a ring
    l0, l1 = q["lettersLift"]
    for i in range(28):
        n = SCALE[(i % 15) + 2]
        bus.add(pluck(n, 0.7, bright=0.85), l0 + i / 28 * 0.6, 0.16, -0.7 + 1.4 * (i % 7) / 6, 0.6)
        bus.add(bell(note(n, 12), 0.4, tau=0.1, ratio=1.41, index=1.0), l0 + i / 28 * 0.6 + 0.01, 0.06, 0, 0.6)
    d = l1 - (l0 + 0.9) + 0.4
    swirl = svf(noise(d), sweep(600, 3000, d), q=1.8, mode="bp") * 2 * np.sin(np.pi * tt(d) / d)
    th = (1.4 * (tt(d) + 0.9)) * 2
    s = int(round((l0 + 0.9) * SR))
    k = min(len(swirl), len(bus.L) - s)
    bus.L[s:s + k] += 0.35 * np.cos((np.sin(th[:k]) + 1) * np.pi / 4) * swirl[:k]
    bus.R[s:s + k] += 0.35 * np.sin((np.sin(th[:k]) + 1) * np.pi / 4) * swirl[:k]
    bus.add(sparkle(1.6, 18, gain=0.25), l0 + 0.9, 0.5, 0, 0.6)

    # ---------------------------------------------------- the logo card and the drop
    k0, _ = q["card"]
    bus.add(paper_pop(380), k0, 0.6, 0, 0.3)
    bus.add(page_turn(0.5), k0, 0.3)
    dr = q["drop"]
    bus.add(riser(dr - k0, 500, 8000), k0, 0.3, 0, 0.3)
    bus.add(swell(0.7), dr - 0.7, 0.35, 0, 0.3)
    bus.add(boom(3.0), dr, 1.0, 0, 0.5)
    bus.add(doum(0.7), dr, 1.0)
    bus.add(tek(), dr + 0.12, 0.5, 0.3)
    bus.add(doum(0.5), dr + 0.25, 0.7)
    for j, n in enumerate(["D4", "F#4", "A4", "D5", "F#5", "A5", "D6"]):
        bus.add(pluck(n, 2.4, bright=0.85, decay=0.998), dr + 0.03 * j, 0.32, -0.7 + j * 0.23, 0.6)
    for n, p in (("D6", -0.3), ("F#6", 0.0), ("A6", 0.3)):
        bus.add(bell(n, 3.0, tau=1.0, ratio=2.0, index=0.9), dr + 0.05, 0.25, p, 0.8)
    bus.add(saw_pad(CHORDS["D"] + ["F#4", "A4"], dur - dr, cutoff=1800, a=0.05, r=1.4), dr, 0.24, 0, 0.6)
    bus.add(saw_pad(["D2", "A2"], dur - dr, cutoff=400, a=0.05, r=1.4), dr, 0.3)
    bus.add(sparkle(2.4, 20, gain=0.3), dr + 0.2, 0.6, 0, 0.7)
    sh0, _ = q["shine"]
    for j, n in enumerate(["D6", "F#6", "A6", "D7", "F#7", "A7"]):
        bus.add(glass(n, 0.5, tau=0.12), sh0 + j * 0.06, 0.2, -0.6 + j * 0.24, 0.6)
    return bus


# ================================================================ master & write

def master(bus):
    rl, rr = hall(bus.send)
    L, R = bus.L + 0.55 * rl, bus.R + 0.55 * rr
    dur = CUES["duration"]
    n = n_of(dur)
    L, R = L[:n], R[:n]
    f0, f1 = CUES["fadeOut"]
    env = np.ones(n)
    a, b = n_of(f0), n_of(f1)
    env[a:b] = np.linspace(1, 0, b - a) ** 1.5
    env[b:] = 0
    L, R = L * env, R * env
    # bus compressor (4:1 above -12 dB, 8 ms attack, 200 ms release) so the
    # groove sits up with the hits, then level and soft-clip anything above 0.8
    peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
    L, R = L / peak, R / peak
    level = np.maximum(np.abs(L), np.abs(R)).tolist()
    att, rel = np.exp(-1 / (0.008 * SR)), np.exp(-1 / (0.2 * SR))
    env, e = np.empty(n), 0.0
    for i, v in enumerate(level):
        e = (att if v > e else rel) * (e - v) + v
        env[i] = e
    thr, ratio = 10 ** (-12 / 20), 4.0
    gain = np.where(env > thr, (np.maximum(env, 1e-9) / thr) ** (1 / ratio - 1), 1.0)
    L, R = L * gain, R * gain
    # push the whole mix up, then a look-ahead limiter (3 ms blocks, 120 ms release)
    peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
    L, R = L / peak * 2.4, R / peak * 2.4
    blk = 128
    nb = -(-n // blk)
    lvl = np.pad(np.maximum(np.abs(L), np.abs(R)), (0, nb * blk - n)).reshape(nb, blk).max(1)
    need = np.minimum(1.0, 0.9 / np.maximum(lvl, 1e-9))
    need = np.minimum(need, np.minimum(np.roll(need, 1), np.roll(need, -1)))
    relb = 1 - np.exp(-blk / (0.12 * SR))
    g, gs = 1.0, np.empty(nb)
    for i in range(nb):
        g = need[i] if need[i] < g else g + (1 - g) * relb
        gs[i] = g
    curve = np.interp(np.arange(n), np.arange(nb) * blk + blk / 2, gs)
    L, R = L * curve, R * curve

    def soft(x):
        k = 0.8
        y = x.copy()
        o = np.abs(y) > k
        y[o] = np.sign(y[o]) * (k + (0.98 - k) * np.tanh((np.abs(y[o]) - k) / (0.98 - k)))
        return y
    return soft(L), soft(R)


def write_stereo(path, L, R):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = np.empty(len(L) * 2, "<i2")
    pcm[0::2] = (np.clip(L, -1, 1) * 32767).astype("<i2")
    pcm[1::2] = (np.clip(R, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def register():
    m = json.load(open(MANIFEST))
    music = m.setdefault("music", {})
    for old in ("intro_logo_blocks", "intro_logo_swarm"):
        music.pop(old, None)
    music[OUT_ID] = dict(
        file=f"music/{OUT_ID}.wav",
        desc="Grandpa's Pop-up Book intro score (25 s, 120 BPM, D hijaz): clock, lamp, qanun motif, creaking cover, paper pops, Nile water, desert wind, pigeons, page turns, rising alphabet, final drop. Synced to remotion/src/intro/cues.json.",
        duration=CUES["duration"],
        source="social/tools/synth_intro.py",
    )
    with open(MANIFEST, "w") as f:
        json.dump(m, f, indent=2, ensure_ascii=False)
        f.write("\n")


if __name__ == "__main__":
    L, R = master(score())
    write_stereo(OUT_WAV, L, R)
    register()
    print(f"score: {OUT_WAV} ({len(L) / SR:.1f} s)")
