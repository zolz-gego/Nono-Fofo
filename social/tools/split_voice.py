#!/usr/bin/env python3
"""Split one ElevenLabs take containing all of a video's lines into line files.

Finds the pauses between lines and writes voice/<line id>.wav for each line in
video.json order. Prints the pauses it found; if the count doesn't match the
lines, pass --gap to change the shortest pause it treats as a break.

Run:  tools/.venv/bin/python social/tools/split_voice.py <video-folder> <take.mp3> [--gap 0.15]
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main(folder, take, min_gap=0.15):
    vdir = os.path.join(ROOT, "social", "videos", folder)
    ids = [s["line"]["id"] for s in json.load(open(os.path.join(vdir, "video.json")))["scenes"] if s.get("line")]
    os.makedirs(os.path.join(vdir, "voice"), exist_ok=True)
    keep = os.path.join(vdir, "voice", "full_take" + os.path.splitext(take)[1])
    if os.path.abspath(take) != os.path.abspath(keep):
        shutil.copy(take, keep)

    tmp = os.path.join(tempfile.mkdtemp(), "take.wav")
    subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "1", take, tmp], check=True)
    w = wave.open(tmp)
    sr = w.getframerate()
    x = np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(float)

    hop = sr // 100
    db = np.array([20 * np.log10(np.sqrt(np.mean((x[i:i + hop] / 32768) ** 2)) + 1e-9) for i in range(0, len(x) - hop, hop)])
    on = db > db.max() - 38
    voiced = np.nonzero(on)[0]
    start, end = voiced[0], voiced[-1] + 1
    gaps, i = [], start
    while i < end:
        if not on[i]:
            j = i
            while j < end and not on[j]:
                j += 1
            if j - i >= min_gap * 100:
                gaps.append((i, j))
            i = j
        else:
            i += 1
    # keep the longest pauses as line breaks
    gaps = sorted(sorted(gaps, key=lambda g: g[0] - g[1])[: len(ids) - 1])
    print("pauses:", ", ".join(f"{a / 100:.2f}-{b / 100:.2f}s" for a, b in gaps))
    if len(gaps) != len(ids) - 1:
        sys.exit(f"found {len(gaps) + 1} parts for {len(ids)} lines; try a smaller --gap")

    bounds = [start] + [v for g in gaps for v in g] + [end]
    for k, lid in enumerate(ids):
        a = max(0, bounds[2 * k] / 100 - 0.04)
        b = min(len(x) / sr, bounds[2 * k + 1] / 100 + 0.12)
        y = x[int(a * sr):int(b * sr)].copy()
        f = sr // 100
        y[:f] *= np.linspace(0, 1, f)
        y[-f:] *= np.linspace(1, 0, f)
        with wave.open(os.path.join(vdir, "voice", lid + ".wav"), "wb") as o:
            o.setnchannels(1)
            o.setsampwidth(2)
            o.setframerate(sr)
            o.writeframes(y.astype("<i2").tobytes())
        print(f"{lid:14s} {b - a:5.2f}s")


if __name__ == "__main__":
    args = sys.argv[1:]
    gap = 0.15
    if "--gap" in args:
        k = args.index("--gap")
        gap = float(args[k + 1])
        del args[k:k + 2]
    main(args[0], args[1], gap)
