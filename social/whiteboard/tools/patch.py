"""Whiteboard letter videos: swap some lines of the full take for a re-recorded piece.

The user recorded the whole script (voice/full.mp3), then re-recorded a few
lines in a second file. This lines both files up with the script (Whisper, as
split.py does), cuts those lines out of the full take, puts the new recording
in their place (with a short pause on each side) and writes voice/full.mp3.
The first full take is kept as voice/full.orig.mp3, and every run starts from it.
Then run split.py as usual.

Run (from the repo root):
  tools/.venv/bin/python social/whiteboard/tools/patch.py <folder> <piece.mp3> <first line> <last line>
  tools/.venv/bin/python social/whiteboard/tools/patch.py <folder> <piece.mp3> 12,14 --on-current
Lines are numbered from 1 in script order (the order split.py prints). The piece
holds those lines in order (a list may skip lines). --on-current patches the
current voice/full.mp3 (keeping earlier patches) instead of the first take.
"""

import json
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
import split  # noqa: E402

SR = 44100
GAP = 0.7  # pause on each side of the new piece (s)


def decode(mp3: Path) -> np.ndarray:
    wav = Path(tempfile.mkdtemp()) / "a.wav"
    subprocess.run(["npx", "remotion", "ffmpeg", "-v", "error", "-y", "-i", str(mp3), "-ac", "1", "-ar", str(SR), str(wav)], cwd=split.REMOTION, check=True)
    w = wave.open(str(wav))
    return (np.frombuffer(w.readframes(w.getnframes()), np.int16) / 32768).astype(np.float32)


def encode(x: np.ndarray, mp3: Path) -> None:
    wav = Path(tempfile.mkdtemp()) / "a.wav"
    w = wave.open(str(wav), "wb")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes())
    w.close()
    subprocess.run(["npx", "remotion", "ffmpeg", "-v", "error", "-y", "-i", str(wav), "-b:a", "192k", str(mp3)], cwd=split.REMOTION, check=True)


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) < 3:
        sys.exit(__doc__)
    folder = split.WHITEBOARD / "videos" / args[0]
    piece = Path(args[1]).resolve()
    if len(args) == 4:  # <first> <last>
        which = list(range(int(args[2]), int(args[3]) + 1))
    else:  # a list: 12,14
        which = sorted(int(n) for n in args[2].split(","))
    voice = folder / "voice"
    orig = voice / "full.orig.mp3"
    if not orig.exists():
        shutil.copyfile(voice / "full.mp3", orig)
    base = voice / "full.mp3" if "--on-current" in sys.argv else orig
    lines = split.says(json.loads((folder / "whiteboard.json").read_text()))
    if not all(1 <= n <= len(lines) for n in which):
        sys.exit(f"lines must be within 1-{len(lines)}")

    # where every line sits in the base take
    spans, _, _ = split.align(split.load(base), lines)

    # the new piece: each of its lines without the silence around it
    px = split.load(piece)
    pspans, _, _ = split.align(px, [lines[n - 1] for n in which])
    gaps = split.pauses(px)
    pdur = len(px) / 16000
    trimmed = []
    for k, (a0, a1) in enumerate(pspans):
        a0 = next((g[1] - 0.08 for g in gaps if g[0] <= a0 + 0.05 and g[1] > a0), a0) if k == 0 else a0
        if k == len(pspans) - 1:
            a1 = next((g[0] + 0.08 for g in gaps if g[1] > pdur - 0.05), a1)
        trimmed.append((a0, a1))
    for n, (a0, a1) in zip(which, trimmed):
        print(f"piece {a0:6.2f}-{a1:6.2f}  line {n}: {lines[n - 1]}")

    full, new = decode(base), decode(piece)
    s = lambda t: int(round(t * SR))  # noqa: E731
    gap = np.zeros(s(GAP), np.float32)
    # replace from the last line back, so earlier cut points stay valid
    for n, (a0, a1) in reversed(list(zip(which, trimmed))):
        cut = spans[n - 2][1] if n > 1 else 0.0
        resume = spans[n][0] if n < len(lines) else len(full) / SR
        full = np.concatenate([full[:s(cut)], gap, new[s(a0):s(a1)], gap, full[s(resume):]])
        print(f"line {n}: base {cut:.2f}-{resume:.2f}s replaced")
    encode(full, voice / "full.mp3")
    print(f"-> {voice / 'full.mp3'} (from {base.name})")


if __name__ == "__main__":
    main()
