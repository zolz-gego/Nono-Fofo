"""Tiny synth toolkit for the Nono & Fofo sound effects (numpy only).

Every function returns a mono float array at SR. Build sounds by layering
instruments with Mix, then pass the result to finish().
"""
import math
import wave

import numpy as np

SR = 44100
rng = np.random.default_rng(7)

_NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6,
         "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def hz(note):
    """'C5' -> 523.25. Numbers pass through unchanged."""
    if not isinstance(note, str):
        return float(note)
    midi = 12 * (int(note[-1]) + 1) + _NOTE[note[:-1]]
    return 440.0 * 2 ** ((midi - 69) / 12)


def n_of(d):
    return max(1, int(round(d * SR)))


def tt(d):
    return np.arange(n_of(d)) / SR


# ---------------------------------------------------------------- envelopes

def perc(d, a=0.003, tau=0.15):
    """Fast attack, exponential decay."""
    t = tt(d)
    e = np.exp(-np.maximum(t - a, 0) / tau)
    if a > 0:
        e *= np.clip(t / a, 0, 1)
    return _tail(e)


def ahr(d, a=0.01, r=0.05):
    """Attack, hold, linear release (for sustained tones)."""
    n = n_of(d)
    e = np.ones(n)
    na, nr = min(n, n_of(a)), min(n, n_of(r))
    e[:na] = np.linspace(0, 1, na)
    e[n - nr:] *= np.linspace(1, 0, nr)
    return e


def hump(d):
    """Smooth rise-and-fall (whooshes)."""
    return np.sin(np.linspace(0, np.pi, n_of(d))) ** 2


def _tail(e, ms=4):
    k = min(len(e), int(SR * ms / 1000))
    e[len(e) - k:] *= np.linspace(1, 0, k)
    return e


# ---------------------------------------------------------------- oscillators

def sweep(f0, f1, d, curve="exp"):
    """Frequency curve from f0 to f1."""
    f0, f1 = hz(f0), hz(f1)
    x = np.linspace(0, 1, n_of(d))
    if curve == "exp":
        return f0 * (f1 / f0) ** x
    if curve == "fast":            # most of the move happens early
        return f1 + (f0 - f1) * np.exp(-x * 6)
    return f0 + (f1 - f0) * x


def osc(freq, d, kind="sine", vib=0.0, vib_rate=6.0):
    n = n_of(d)
    f = np.full(n, hz(freq)) if np.isscalar(freq) or isinstance(freq, str) else np.asarray(freq[:n], float)
    if len(f) < n:
        f = np.concatenate([f, np.full(n - len(f), f[-1])])
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * vib_rate * tt(d)))
    p = 2 * np.pi * np.cumsum(f) / SR
    if kind == "sine":
        return np.sin(p)
    if kind == "tri":
        return 2 / np.pi * np.arcsin(np.sin(p))
    if kind == "square":
        return np.tanh(3.5 * np.sin(p))
    if kind == "saw":
        return sum(((-1) ** (k + 1)) * np.sin(k * p) / k for k in range(1, 14)) * (2 / np.pi)
    raise ValueError(kind)


def noise(d):
    return rng.uniform(-1, 1, n_of(d))


# ---------------------------------------------------------------- filters

def svf(x, fc, q=0.7, mode="lp"):
    """Zero-delay state variable filter. fc may be a number or an array."""
    n = len(x)
    fc = np.clip(np.broadcast_to(np.asarray(fc, float), (n,)), 20, SR * 0.45)
    g = np.tan(np.pi * fc / SR)
    k = 1.0 / q
    a1 = 1 / (1 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    out = np.empty(n)
    ic1 = ic2 = 0.0
    xs, A1, A2, A3 = x.tolist(), a1.tolist(), a2.tolist(), a3.tolist()
    lp, bp = mode == "lp", mode == "bp"
    for i in range(n):
        v0 = xs[i]
        v3 = v0 - ic2
        v1 = A1[i] * ic1 + A2[i] * v3
        v2 = ic2 + A2[i] * ic1 + A3[i] * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        out[i] = v2 if lp else v1 if bp else v0 - k * v1 - v2
    return out


def _fftconv(a, b):
    n = len(a) + len(b) - 1
    size = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(a, size) * np.fft.rfft(b, size), size)[:n]


_IR = {}


def reverb(x, wet=0.15, size=1.0, tau=0.22):
    """Small, bright room. Lengthens the sound by `size` seconds."""
    key = (size, tau)
    if key not in _IR:
        ir = noise(size) * np.exp(-tt(size) / tau)
        ir = svf(ir, 6000, mode="lp")
        _IR[key] = ir / np.sqrt(np.sum(ir ** 2))
    y = _fftconv(x, _IR[key])
    dry = np.concatenate([x, np.zeros(len(y) - len(x))])
    return dry + wet * y


# ---------------------------------------------------------------- mixing

class Mix:
    def __init__(self):
        self.buf = np.zeros(1)

    def add(self, sig, at=0.0, gain=1.0):
        start = int(round(at * SR))
        end = start + len(sig)
        if end > len(self.buf):
            self.buf = np.concatenate([self.buf, np.zeros(end - len(self.buf))])
        self.buf[start:end] += gain * sig
        return self

    def out(self):
        return self.buf


def loudness(x, win=0.05):
    """Loudest short-term RMS in dBFS (what the ear notices on short sounds)."""
    k = n_of(win)
    if len(x) <= k:
        return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-12)
    sq = np.convolve(x ** 2, np.ones(k) / k, mode="valid")
    return 10 * np.log10(np.max(sq) + 1e-12)


def finish(x, vol=0.8, ceiling=0.95):
    """Trim, fade, and level so sounds of the same `vol` feel equally loud
    (vol 0.8 -> -11 dB short-term loudness), never peaking above `ceiling`."""
    x = x - np.mean(x)
    loud = np.nonzero(np.abs(x) > np.max(np.abs(x)) * 10 ** (-58 / 20))[0]
    x = x[: loud[-1] + 1] if len(loud) else x
    x = _tail(x.copy(), ms=12)
    target = -11 + 20 * np.log10(vol / 0.8)
    x = x * 10 ** ((target - loudness(x)) / 20)
    peak = np.max(np.abs(x))
    if peak > ceiling * 2:          # very spiky sound (clicks): give up some loudness
        x *= ceiling * 2 / peak
    if peak > ceiling * 0.7:        # soft-clip only the transients above 70%
        knee = ceiling * 0.7
        over = np.abs(x) > knee
        x[over] = np.sign(x[over]) * (knee + (ceiling - knee) * np.tanh((np.abs(x[over]) - knee) / (ceiling - knee)))
    return x


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# ---------------------------------------------------------------- instruments

def marimba(f, d=0.6, tau=0.18):
    f = hz(f)
    return (osc(f, d) * perc(d, 0.002, tau)
            + 0.35 * osc(f * 4, d) * perc(d, 0.001, tau * 0.25)
            + 0.10 * osc(f * 9.9, d) * perc(d, 0.001, tau * 0.08))


def bell(f, d=1.2, tau=0.45, ratio=3.5, index=2.0):
    """FM bell / glockenspiel."""
    f = hz(f)
    t = tt(d)
    mod = np.sin(2 * np.pi * f * ratio * t) * index * np.exp(-t / (tau * 0.6))
    return (np.sin(2 * np.pi * f * t + mod) * perc(d, 0.001, tau)
            + 0.2 * osc(f * 2.76, d) * perc(d, 0.001, tau * 0.4))


def pluck(f, d=0.8, bright=0.6, decay=0.996):
    """Karplus-Strong string (qanun / oud-ish)."""
    f = hz(f)
    period = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, period)
    if bright < 1:
        buf = svf(buf, 1500 + 9000 * bright, mode="lp") * 2
    buf = buf.tolist()
    n = n_of(d) + 2
    out = [0.0] * n
    for i in range(n):
        j = i % period
        out[i] = buf[j]
        buf[j] = decay * 0.5 * (buf[j] + buf[(j + 1) % period])
    out = np.array(out)
    # retune: the integer delay line is slightly off-pitch
    ratio = (SR / period) / f
    src = np.arange(n_of(d)) * ratio
    y = np.interp(src, np.arange(n), out)
    return y * ahr(d, 0.001, 0.02)


def tone(f, d, kind="tri", a=0.01, r=0.06, vib=0.0):
    return osc(f, d, kind, vib=vib) * ahr(d, a, r)


def chime(f, d=0.9):
    """Soft rounded ding."""
    return bell(f, d, tau=0.35, ratio=2.0, index=0.8)


def glass(f, d=0.6, tau=0.18):
    f = hz(f)
    return sum(a * osc(f * m, d) * perc(d, 0.0005, tau / (1 + i))
               for i, (m, a) in enumerate([(1, 1), (2.32, 0.6), (4.25, 0.35), (6.63, 0.2)]))


# ---------------------------------------------------------------- cartoon parts

def pop(f=700, d=0.09):
    body = osc(sweep(f * 1.9, f * 0.7, d, "fast"), d) * perc(d, 0.001, 0.025)
    click = svf(noise(d), 3000, q=0.8, mode="hp") * perc(d, 0.0005, 0.004)
    return body + 0.5 * click


def bubble(f=500, d=0.08):
    """Water drop: pitch rises (real bubble physics)."""
    return osc(sweep(f, f * 2.4, d, "exp"), d) * perc(d, 0.002, d * 0.35)


def click(d=0.03, f=4000):
    return svf(noise(d), f, q=1.2, mode="bp") * perc(d, 0.0003, 0.004)


def wood(f=900, d=0.15):
    f = hz(f)
    return (osc(f, d) * perc(d, 0.0008, 0.035)
            + 0.5 * osc(f * 2.7, d) * perc(d, 0.0005, 0.015)
            + 0.3 * click(d, f * 3))


def clack(f=2200, d=0.08):
    """Hard plastic / dice hit."""
    return (2.5 * svf(noise(d), f, q=5, mode="bp") * perc(d, 0.0003, 0.012)
            + 0.4 * osc(f * 0.35, d) * perc(d, 0.0005, 0.02))


def thud(f=70, d=0.3):
    body = osc(sweep(f * 2.2, f, d, "fast"), d) * perc(d, 0.002, 0.07)
    dirt = svf(noise(d), 400, mode="lp") * perc(d, 0.001, 0.03)
    return body + 0.8 * dirt


def whoosh(d=0.4, f0=500, f1=3000, q=1.5, gain=1.0):
    return gain * 2 * svf(noise(d), sweep(f0, f1, d), q=q, mode="bp") * hump(d)


def slide_whistle(f0, f1, d, vib=0.012, curve="exp"):
    f = sweep(f0, f1, d, curve)
    breath = svf(noise(d), f * 1.0, q=6, mode="bp") * 0.25
    return (osc(f, d, "sine", vib=vib, vib_rate=7) + breath) * ahr(d, 0.02, 0.05)


def boing(f0=180, f1=420, d=0.45, wobble=0.18):
    t = tt(d)
    f = sweep(f0, f1, d, "fast") * (1 + wobble * np.sin(2 * np.pi * 16 * t) * np.exp(-t / 0.15))
    return osc(f, d, "tri") * perc(d, 0.002, d * 0.45)


def sparkle(d=0.8, count=10, notes=("C7", "D7", "E7", "G7", "A7", "C8"), start=0.0, gain=0.35):
    m = Mix()
    for i in range(count):
        at = start + (d * 0.75) * i / count + rng.uniform(0, 0.02)
        f = hz(notes[rng.integers(len(notes))])
        m.add(bell(f, 0.35, tau=0.08, ratio=1.41, index=1.2), at, gain * rng.uniform(0.5, 1.0))
    return m.out()


def arp(notes, step, inst=marimba, d=0.6, gain=1.0, start=0.0, mix=None):
    m = mix or Mix()
    for i, nt in enumerate(notes):
        m.add(inst(nt, d), start + i * step, gain)
    return m.out() if mix is None else m


def chord(notes, inst=marimba, d=0.8, gain=1.0):
    m = Mix()
    for nt in notes:
        m.add(inst(nt, d), 0, gain / math.sqrt(len(notes)))
    return m.out()


def doum(d=0.4):
    """Darbuka low stroke."""
    return osc(sweep(150, 78, d, "fast"), d) * perc(d, 0.002, 0.16) + 0.2 * svf(noise(d), 300, mode="lp") * perc(d, 0.001, 0.02)


def tek(d=0.12):
    """Darbuka rim stroke."""
    return 1.6 * svf(noise(d), 3800, q=2, mode="bp") * perc(d, 0.0005, 0.02) + 0.3 * osc(620, d) * perc(d, 0.0005, 0.03)


def brass(f, d, wah=True, vib=0.0):
    """Cartoon trombone: saw with an opening/closing filter."""
    x = osc(f, d, "saw", vib=vib, vib_rate=5.5)
    t = tt(d)
    cutoff = 300 + 1500 * (np.sin(np.pi * t / d) if wah else np.ones_like(t))
    return svf(x, cutoff, q=1.5, mode="lp") * ahr(d, 0.03, 0.08)


def impulses(d, rate0, rate1, jitter=0.0):
    """Click train with changing rate (creaks, rattles, ratchets)."""
    n = n_of(d)
    x = np.zeros(n)
    rate = sweep(rate0, rate1, d, "lin")
    ph = 0.0
    for i in range(n):
        ph += rate[i] / SR
        if ph >= 1:
            ph -= 1 + rng.uniform(-jitter, jitter)
            x[i] = rng.uniform(0.6, 1.0)
    return x


def water(d=0.5, bright=2500):
    body = svf(noise(d), bright, mode="lp") - 0.5 * svf(noise(d), 300, mode="lp")
    return body * perc(d, 0.004, d * 0.35)
