#!/usr/bin/env python3
"""Logo intro score ("Golden Letter Swarm"), composed entirely in code.

Reads social/remotion/src/intro/cues.json, the same timeline the picture uses,
so every shape the swarm lands on gets its hit on the same sample.
120 BPM in D hijaz (D Eb F# G A Bb C): darbuka maqsum, bass, pad, qanun
plucks, a granular "swarm shimmer" whose density follows the particles, an
auto-panned spin for the ring, risers and the final drop.

Run:  tools/.venv/bin/python social/tools/synth_intro.py
Out:  social/assets/music/intro_logo_swarm.wav (44.1 kHz stereo 16-bit)
      social/assets/manifest.json ("music" section)
"""
import json
import os
import sys
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "audio"))

from dsp import (SR, bell, boing, chime, doum, glass, hz, marimba, n_of, noise, osc, perc,  # noqa: E402
                 pluck, pop, sparkle, svf, sweep, tek, thud, tt, water, whoosh, wood)

INTRO = os.path.join(ROOT, "social", "remotion", "src", "intro")
CUES = json.load(open(os.path.join(INTRO, "cues.json")))
OUT_ID = "intro_logo_swarm"
OUT_WAV = os.path.join(ROOT, "social", "assets", "music", f"{OUT_ID}.wav")
MANIFEST = os.path.join(ROOT, "social", "assets", "manifest.json")

BEAT = 60 / CUES["bpm"]
BAR = BEAT * 4
EIGHTH = BEAT / 2
SIXTEENTH = BEAT / 4
LAND = {s["shape"]: s["land"] for s in CUES["stages"]}
START = {s["shape"]: s["land"] - s["lead"] for s in CUES["stages"]}


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
STAB = {"D": ["D4", "F#4", "A4", "D5"], "Gm": ["G4", "Bb4", "D5", "G5"], "Cm": ["C5", "Eb5", "G5", "C6"], "Eb": ["Eb4", "G4", "Bb4", "Eb5"]}
# bar start (s) -> chord
PROGRESSION = [(4, "D"), (6, "Gm"), (8, "Cm"), (10, "D"), (12, "Eb"), (14, "D")]
MAQSUM = [("D", 0), ("T", 1), ("T", 3), ("D", 4), ("T", 6)]


def chord_at(t):
    name = "D"
    for start, c in PROGRESSION:
        if t >= start:
            name = c
    return name


def grains(bus, t0, t1, density, notes=("D7", "F#7", "A7", "D8", "A6", "F#6"), gain=0.12, seed=5, pan=None, verb=0.6):
    """Granular shimmer: tiny bell grains, `density(t)` grains per second."""
    rng = np.random.default_rng(seed)
    t = t0
    while t < t1:
        d = max(0.5, density(t))
        f = hz(notes[rng.integers(len(notes))]) * (1 + rng.uniform(-0.004, 0.004))
        p = pan(t) if pan else rng.uniform(-0.9, 0.9)
        bus.add(bell(f, 0.3, tau=0.06, ratio=1.41, index=1.1), t, gain * rng.uniform(0.4, 1.0), p, verb)
        t += rng.exponential(1 / d)


def add_panned(bus, sig, at, pan, gain=1.0, verb=0.0):
    """Add a mono signal whose pan follows the array `pan` (one value per sample)."""
    s = int(round(at * SR))
    sig = sig[: len(bus.L) - s]
    pan = pan[: len(sig)]
    th = (pan + 1) * np.pi / 4
    bus.L[s:s + len(sig)] += gain * np.cos(th) * sig
    bus.R[s:s + len(sig)] += gain * np.sin(th) * sig
    if verb:
        bus.send[s:s + len(sig)] += gain * verb * sig


def morph_whoosh(bus, shape, pan):
    t0, t1 = START[shape], LAND[shape]
    bus.add(whoosh(t1 - t0 + 0.05, 500, 3800, q=1.1), t0, 0.32, pan, 0.3)
    grains(bus, t0, t1, lambda t: 40 * (1 - (t - t0) / (t1 - t0)), gain=0.07, seed=int(t0 * 10))


def stab(bus, at, c, gain=0.28):
    for n, p in zip(STAB[c], (-0.5, -0.15, 0.15, 0.5)):
        bus.add(pluck(n, 1.1, bright=0.75), at, gain, p, 0.45)


def score():
    dur = CUES["duration"]
    bus = Bus(dur + 0.5)

    # ---------------------------------------------------- dust gathers into alpha + omega
    ao, sh = LAND["alphaOmega"], CUES["shatter"]
    drone = saw_pad(["D2", "A2", "D3"], sh + 0.2, cutoff=400, a=1.4, r=0.2)
    drone = svf(drone, sweep(220, 1600, sh + 0.2, "exp"), q=0.9, mode="lp")
    bus.add(drone, 0.0, 0.5, 0, 0.3)
    grains(bus, 0.05, ao, lambda t: 4 + 60 * (t / ao) ** 2, gain=0.09, seed=1)
    bus.add(swell(0.6), ao - 0.6, 0.18, 0, 0.3)
    for n, p in (("D5", -0.3), ("A5", 0.0), ("D6", 0.3)):
        bus.add(bell(n, 2.2, tau=0.8, ratio=2.0, index=0.9), ao, 0.22, p, 0.8)
    bus.add(thud(55, 0.5), ao, 0.35)
    bus.add(glass(hz("A7"), 0.5, tau=0.09), ao + 0.2, 0.2, 0.4, 0.6)
    grains(bus, ao, sh, lambda t: 10, gain=0.06, seed=2)
    bus.add(swell(0.5), sh - 0.5, 0.3, 0, 0.3)

    # ---------------------------------------------------- shatter into the flock
    bus.add(boom(2.0), sh, 0.85, 0, 0.35)
    bus.add(doum(0.6), sh, 0.8)
    bus.add(sparkle(1.2, 26, gain=0.3), sh, 0.7, 0, 0.5)
    for i in range(6):
        bus.add(whoosh(0.35, 700, 5200, q=1.3), sh + i * 0.04, 0.2, -0.9 + i * 0.36, 0.2)
    grains(bus, sh, LAND["swarm"] + 0.4, lambda t: 70 * np.exp(-(t - sh) * 1.5), gain=0.07, seed=3,
           pan=lambda t: np.sin(t * 5))
    bus.add(riser(0.7, 500, 5000), LAND["pyramid"] - 0.7, 0.2, 0, 0.3)

    # ---------------------------------------------------- the groove under the shapes
    g0, g1 = LAND["pyramid"], START["logo"] - 0.25
    for bar in np.arange(g0, g1, BAR):
        light = bar < 8.0
        c = chord_at(bar)
        for kind, slot in MAQSUM:
            at = bar + slot * EIGHTH
            if at >= g1:
                continue
            if kind == "D":
                bus.add(doum(), at, 0.8)
            elif not light:
                bus.add(tek(), at, 0.42, 0.25)
        for s in range(16):
            at = bar + s * SIXTEENTH
            if at < g1:
                bus.add(shaker(), at, 0.15 if s % 2 else 0.22, 0.45)
                if not light and s in (5, 13, 15):
                    bus.add(ka(), at, 0.32, -0.3)
        pat = [(0, ROOTS[c], 1.0), (3, FIFTHS[c], 0.7), (4, ROOTS[c], 0.9), (7, note(ROOTS[c], 12), 0.6)]
        for slot, n, g in pat:
            at = bar + slot * EIGHTH
            if at < g1:
                bus.add(bass(n), at, 0.5 * g)
        bus.add(saw_pad(CHORDS[c], min(BAR, g1 - bar) + 0.3, cutoff=1200, a=0.25, r=0.4), bar, 0.14, 0, 0.5)

    # ---------------------------------------------------- one signature per shape
    pans = {"pyramid": -0.3, "palm": 0.3, "nile": -0.2, "book": 0.2, "brothers": 0.0, "names": 0.0, "vortex": 0.0}
    for shape, p in pans.items():
        morph_whoosh(bus, shape, p)
        if shape != "vortex":
            stab(bus, LAND[shape], chord_at(LAND[shape]))

    t = LAND["pyramid"]                                       # pyramid + sun: deep gong, sun chime
    bus.add(bell("D3", 2.5, tau=0.9, ratio=1.4, index=1.5), t, 0.35, -0.2, 0.5)
    bus.add(chime("A6", 1.2), t + 0.25, 0.25, 0.5, 0.6)
    bus.add(sparkle(0.6, 6), t + 0.25, 0.4, 0.5, 0.5)

    t = LAND["palm"]                                          # palm: leaves in the wind
    for i in range(7):
        bus.add(svf(noise(0.14), 4200, q=1.4, mode="bp") * perc(0.14, 0.012, 0.045), t + 0.05 + i * 0.16, 0.22, -0.6 + i * 0.2)
    for j, n in enumerate(["A5", "G5", "F#5", "D5"]):
        bus.add(marimba(n, 0.5), t + 0.5 + j * SIXTEENTH, 0.28, 0.2, 0.3)

    t = LAND["nile"]                                          # Nile: flowing water and bubbles
    bus.add(water(1.4, 2200), t, 0.3, -0.2, 0.4)
    for j in range(10):
        f = 420 + 70 * (j % 5)
        d = 0.09
        bub = osc(sweep(f, f * 2.4, d, "exp"), d) * perc(d, 0.002, d * 0.35)
        bus.add(bub, t + 0.05 + j * 0.11, 0.22, -0.6 + j * 0.13, 0.4)

    t = LAND["book"]                                          # book: pages flutter, qanun run up
    for i in range(6):
        bus.add(svf(noise(0.06), 2500, q=1.2, mode="bp") * perc(0.06, 0.004, 0.02), t + i * 0.07, 0.3, 0.2)
    for j, n in enumerate(SCALE[7:15]):
        bus.add(pluck(n, 0.6, bright=0.8), t + 0.35 + j * 0.05, 0.2, -0.5 + j * 0.14, 0.4)

    t = LAND["brothers"]                                      # the brothers: two boings + ta-da
    bus.add(boing(150, 360, 0.5), t, 0.55, -0.4, 0.3)
    bus.add(boing(220, 520, 0.45), t + 0.25, 0.5, 0.4, 0.3)
    bus.add(marimba("G5", 0.3), t + 0.6, 0.3)
    bus.add(marimba("C6", 0.8), t + 0.73, 0.3, 0, 0.3)
    bus.add(bell("C7", 1.0, tau=0.35, ratio=2.0, index=1.2), t + 0.73, 0.15, 0, 0.5)

    t = LAND["names"]                                         # names: a little motif for each
    for j, n in enumerate(["A5", "F#5", "A5", "D6"]):
        bus.add(pluck(n, 0.8, bright=0.8), t + j * SIXTEENTH, 0.35, -0.5, 0.5)
    for j, n in enumerate(["D6", "A5", "D6", "F#6"]):
        bus.add(pluck(n, 0.8, bright=0.8), t + BEAT + j * SIXTEENTH, 0.35, 0.5, 0.5)

    # ---------------------------------------------------- the ring spins up
    v0 = START["vortex"]
    s0, s1 = CUES["spinUp"]
    d = s1 - s0 + 0.2
    spin = 1.2 * (tt(d) + (s0 - v0)) + 0.9 * (tt(d) + (s0 - v0)) ** 2
    air = svf(noise(d), sweep(500, 4500, d), q=1.6, mode="bp") * 2 * (tt(d) / d) ** 1.4
    add_panned(bus, air, s0, np.sin(spin), 0.5, 0.3)
    tone_ = osc(sweep(note("D3"), note("D5"), d), d, "saw")
    add_panned(bus, svf(tone_, 1800, mode="lp") * (tt(d) / d) ** 2 * 0.25, s0, np.sin(spin + np.pi), 0.5, 0.3)
    t, gap = s0, EIGHTH
    while t < s1:
        bus.add(tek(), t, 0.2 + 0.4 * (t - s0) / (s1 - s0), 0.3 * np.sin(t * 9))
        t += gap
        gap = max(0.04, gap * 0.9)

    # ---------------------------------------------------- spiral into the logo
    l0, l1 = START["logo"], LAND["logo"]
    grains(bus, l0, l1, lambda t: 25 + 120 * np.sin(np.pi * (t - l0) / (l1 - l0)), gain=0.08, seed=9,
           notes=("D6", "F#6", "A6", "D7", "F#7", "A7", "D8"))
    bus.add(whoosh(l1 - l0, 4000, 500, q=1.0), l0, 0.35, 0, 0.4)
    bus.add(riser(1.2, 600, 9000), CUES["drop"] - 1.2, 0.3, 0, 0.3)
    bus.add(swell(0.7), CUES["drop"] - 0.75, 0.35, 0, 0.3)

    # ---------------------------------------------------- the drop: the logo
    dr = CUES["drop"]
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
    bus.add(sparkle(2.4, 22, gain=0.3), dr + 0.2, 0.6, 0, 0.7)
    sh0, _ = CUES["shine"]
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
    music.pop("intro_logo_blocks", None)
    music[OUT_ID] = dict(
        file=f"music/{OUT_ID}.wav",
        desc="Golden Letter Swarm intro score (24 s, 120 BPM, D hijaz): granular swarm shimmer, darbuka, qanun, a signature per shape, ring spin, final drop. Synced to remotion/src/intro/cues.json.",
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
