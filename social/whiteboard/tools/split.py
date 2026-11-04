"""Whiteboard letter videos: time a take the user made in ElevenLabs.

The user pastes the whole script (one line per `say`, v3 tags allowed) into
ElevenLabs and saves the result as social/whiteboard/videos/<id>/voice/full.mp3. This
transcribes it with Whisper (word timestamps), lines the transcript up with
the `say` lines of whiteboard.json, snaps every cut into the nearest pause and
writes voice/take.mp3 + voice/take.json (the text of every `say` with the
start/end second of each character, plus each line's span),
so the whiteboard engine (social/whiteboard/engine) plays each line on its own beat.

Run (from the repo root): tools/.venv/bin/python social/whiteboard/tools/split.py wb-01-alpha-ar
"""

import difflib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

WHITEBOARD = Path(__file__).resolve().parents[1]
SOCIAL = WHITEBOARD.parent

REMOTION = SOCIAL / "remotion"


def norm(s: str) -> str:
    """Letters only, with the Arabic spellings Whisper and scripts disagree on folded together."""
    s = re.sub(r"\[[^\]]*\]", "", s)
    s = re.sub(r"[ً-ْـ]", "", s)  # harakat, tatweel
    s = s.translate(str.maketrans("أإآٱةى", "ااااهي"))
    return re.sub(r"[^\w]", "", s).lower()


def says(spec: dict) -> list[str]:
    out = list(spec["intro"]["say"]) + [f["say"] for f in spec.get("facts", [])]
    for sec in spec["sections"]:
        out.append(sec["say"])
        for w in sec["words"]:
            out += [w["say"]] + ([w["spellSay"]] if w.get("spellSay") else [])
        if sec.get("note"):
            out.append(sec["note"]["say"])
    return out + [spec["recap"]["say"], spec["end"]["say"]]


def load(mp3: Path) -> np.ndarray:
    wav = Path(tempfile.mkdtemp()) / "a.wav"
    subprocess.run(["npx", "remotion", "ffmpeg", "-v", "error", "-y", "-i", str(mp3), "-ac", "1", "-ar", "16000", str(wav)], cwd=REMOTION, check=True)
    w = wave.open(str(wav))
    return (np.frombuffer(w.readframes(w.getnframes()), np.int16) / 32768).astype(np.float32)


def pauses(x: np.ndarray, sr=16000, hop=0.02) -> list[tuple[float, float]]:
    n = int(sr * hop)
    db = 20 * np.log10(np.array([np.sqrt(np.mean(x[i:i + n] ** 2)) for i in range(0, len(x) - n, n)]) + 1e-9)
    quiet = db < db.max() - 40
    runs, start = [], None
    for i, q in enumerate(quiet):
        if q and start is None:
            start = i
        if not q and start is not None:
            if (i - start) * hop >= 0.2:
                runs.append((start * hop, i * hop))
            start = None
    return runs


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)

    folder = WHITEBOARD / "videos" / sys.argv[1]
    spec = json.loads((folder / "whiteboard.json").read_text())
    lines = says(spec)
    x = load(folder / "voice" / "full.mp3")
    spans, at, owner = align(x, lines)
    write_take(folder, lines, spans, at, owner)
    for l, (a0, a1) in zip(lines, spans):
        print(f"{a0:6.2f}-{a1:6.2f}  {l}")


def align(x: np.ndarray, lines: list[str]):
    """Each line's [start, end] in x (cut in pauses), plus the heard time of every script letter."""
    import mlx_whisper

    dur = len(x) / 16000
    r = mlx_whisper.transcribe(x, path_or_hf_repo="mlx-community/whisper-large-v3-turbo", language="ar", word_timestamps=True, condition_on_previous_text=False)

    # transcript letters, each with the time of the word it belongs to
    heard, times = "", []
    for seg in r["segments"]:
        for w in seg.get("words", []):
            if w["start"] >= dur:
                continue
            t = norm(w["word"])
            heard += t
            times += [(w["start"] + (w["end"] - w["start"]) * k / max(1, len(t)), w["end"]) for k in range(len(t))]
    script = "".join(norm(l) for l in lines)
    owner = [i for i, l in enumerate(lines) for _ in norm(l)]

    # map every script letter to a transcript letter, then take each line's first one
    m = difflib.SequenceMatcher(None, script, heard, autojunk=False)
    at = [None] * len(script)
    for a, b, size in m.get_matching_blocks():
        for k in range(size):
            at[a + k] = times[b + k][0]
    starts = []
    for i in range(len(lines)):
        ts = [at[j] for j, o in enumerate(owner) if o == i and at[j] is not None]
        starts.append(min(ts) if ts else None)
    starts[0] = 0.0
    for i in range(1, len(starts)):  # fill gaps and keep them in order
        if starts[i] is None or starts[i] <= starts[i - 1]:
            starts[i] = starts[i - 1] + 0.5

    # cut in the pause nearest each line start
    gaps = pauses(x)
    spans = []
    for i, s in enumerate(starts):
        a0 = s
        if i:
            near = min(gaps, key=lambda g: min(abs(g[0] - s), abs(g[1] - s)), default=None)
            if near and min(abs(near[0] - s), abs(near[1] - s)) < 0.7:
                spans[-1][1] = near[0] + 0.08
                a0 = max(near[1] - 0.08, near[0])
            else:
                spans[-1][1] = s
        spans.append([a0, dur])

    return spans, at, owner


def char_times(lines, spans, at, owner):
    """Per line, the time of every character: heard (Whisper) where the letter
    was matched, else filled in between its neighbours; the first character
    starts the line's span and the last ends it, so the clip cuts stay in the pauses."""
    heard_of = {}  # (line, letter index in norm(line)) -> time
    k = {}
    for j, o in enumerate(owner):
        n = k.get(o, 0)
        if at[j] is not None:
            heard_of[(o, n)] = at[j]
        k[o] = n + 1
    out = []
    for i, (l, (a0, a1)) in enumerate(zip(lines, spans)):
        t, n = [None] * len(l), 0
        for c_i, c in enumerate(l):
            for _ in norm(c):
                h = heard_of.get((i, n))
                if h is not None and t[c_i] is None and a0 <= h <= a1:
                    t[c_i] = h
                n += 1
        t[0] = a0
        known = [c for c in range(len(l)) if t[c] is not None]
        for c in range(len(l)):  # fill gaps linearly, end anchored at a1
            if t[c] is None:
                prev = max(q for q in known if q < c)
                nxt = min((q for q in known if q > c), default=None)
                hi_t, hi_c = (t[nxt], nxt) if nxt is not None else (a1, len(l))
                t[c] = t[prev] + (hi_t - t[prev]) * (c - prev) / (hi_c - prev)
        for c in range(1, len(l)):  # keep them in order
            t[c] = max(t[c], t[c - 1])
        out.append(t)
    return out


def level(src: Path, dst: Path, sr: int = 44100, boost_db: float = 12.0) -> None:
    """A slow voice leveller: phrases quieter than the take's usual speaking level
    (whispers, a soft line) are lifted towards it, by up to `boost_db`. The level is
    measured over voiced frames only (so pauses don't count), across ~0.5 s, and
    the gain glides; nothing is made quieter except peaks over -1 dBFS (limiter)."""
    wav = Path(tempfile.mkdtemp()) / "a.wav"
    subprocess.run(["npx", "remotion", "ffmpeg", "-v", "error", "-y", "-i", str(src), "-ac", "1", "-ar", str(sr), str(wav)], cwd=REMOTION, check=True)
    w = wave.open(str(wav))
    x = (np.frombuffer(w.readframes(w.getnframes()), np.int16) / 32768).astype(np.float32)
    hop = int(sr * 0.02)
    nfr = len(x) // hop
    p = np.array([np.mean(x[i * hop:(i + 1) * hop] ** 2) for i in range(nfr)]) + 1e-12
    db = 10 * np.log10(p)
    voiced = db > db.max() - 38
    win = np.ones(25)  # 0.5 s
    env = np.convolve(p * voiced, win, "same") / np.maximum(np.convolve(voiced.astype(float), win, "same"), 1e-9)
    env_db = 10 * np.log10(env + 1e-12)
    target = np.percentile(env_db[voiced], 60)
    gain_db = np.where(np.convolve(voiced.astype(float), win, "same") > 0, np.clip(target - env_db, 0, boost_db), 0)
    gain_db = np.convolve(gain_db, np.ones(15) / 15, "same")  # glide over 0.3 s
    g = 10 ** (np.interp(np.arange(len(x)), np.arange(nfr) * hop + hop / 2, gain_db) / 20)
    y = x * g
    # peak limiter: only the blocks that would go over -1 dBFS are turned down (5 ms blocks, gliding)
    blk = int(sr * 0.005)
    nb = len(y) // blk + 1
    peaks = np.array([np.abs(y[i * blk:(i + 1) * blk]).max(initial=0) for i in range(nb)])
    lim = np.minimum(1, 0.89 / np.maximum(peaks, 1e-9))
    lim = np.minimum.reduce([np.roll(lim, k) for k in range(-3, 4)])  # look ahead / hold
    lim = np.convolve(lim, np.ones(5) / 5, "same")
    y = y * np.interp(np.arange(len(y)), np.arange(nb) * blk + blk / 2, lim)
    y = np.clip(y, -0.95, 0.95)
    out = Path(tempfile.mkdtemp()) / "b.wav"
    o = wave.open(str(out), "wb")
    o.setnchannels(1)
    o.setsampwidth(2)
    o.setframerate(sr)
    o.writeframes((y * 32767).astype(np.int16).tobytes())
    o.close()
    subprocess.run(["npx", "remotion", "ffmpeg", "-v", "error", "-y", "-i", str(out), "-b:a", "192k", str(dst)], cwd=REMOTION, check=True)


def write_take(folder: Path, lines, spans, at, owner) -> None:
    """take.json: the narration text with the time of every character, plus each line's span."""
    times = char_times(lines, spans, at, owner)
    text, start, end = "", [], []
    for i, (l, (a0, a1), t) in enumerate(zip(lines, spans, times)):
        if i:
            text += "\n"
            start.append(a0)
            end.append(a0)
        for c_i, c in enumerate(l):
            text += c
            start.append(t[c_i])
            end.append(t[c_i + 1] if c_i + 1 < len(l) else a1)
    level(folder / "voice" / "full.mp3", folder / "voice" / "take.mp3")
    (folder / "voice" / "take.json").write_text(json.dumps({"text": text, "start": start, "end": end, "lines": spans}, ensure_ascii=False))


if __name__ == "__main__":
    main()
