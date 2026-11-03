"""Render a HyperFrames project on this Mac, which has no full ffmpeg.

HyperFrames' own `render` needs ffmpeg filters that the only ffmpeg here (the
one bundled with Remotion) lacks. So this:
  1. renders the picture as a PNG sequence with HyperFrames (audio tags removed
     from a temporary copy of index.html),
  2. mixes every <audio> of index.html itself (data-start, data-media-start,
     data-duration, data-volume, data-fade-in/out) with numpy,
  3. encodes picture + mix with the bundled ffmpeg (no filters needed).
Remove this once `brew install ffmpeg` is done: then `npx hyperframes render` works.

Run (from the repo root): tools/.venv/bin/python social/tools/hf_render.py social/hyperframes/<project> [out.mp4] [--hq]
--hq: the release encode (H.264 CRF 12 slow, AAC 320k) instead of the draft one.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
FF = ROOT / "social" / "remotion" / "node_modules" / "@remotion" / "compositor-darwin-arm64"
SR = 48000


def tools_path() -> str:
    """A PATH with ffmpeg/ffprobe wrappers around the Remotion build (it needs its dylib folder)."""
    d = Path(tempfile.gettempdir()) / "ffwrap"
    d.mkdir(exist_ok=True)
    for b in ("ffmpeg", "ffprobe"):
        f = d / b
        f.write_text(f'#!/bin/sh\nexport DYLD_LIBRARY_PATH="{FF}"\nexec "{FF / b}" "$@"\n')
        f.chmod(0o755)
    return f"{d}:{os.environ['PATH']}"


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    hq = "--hq" in sys.argv
    if not args:
        sys.exit(__doc__)
    proj = Path(args[0]).resolve()
    out = Path(args[1]).resolve() if len(args) > 1 else proj / "renders" / f"{proj.name}.mp4"
    env = {**os.environ, "PATH": tools_path()}
    index = proj / "index.html"
    html = index.read_text()
    dur = float(re.search(r'data-composition-id="main"[^>]*data-duration="([\d.]+)"', html).group(1))

    # 1. picture
    frames = proj / "renders" / "frames"
    shutil.rmtree(frames, ignore_errors=True)
    backup = index.with_suffix(".html.bak")
    shutil.copyfile(index, backup)
    try:
        index.write_text(re.sub(r"\s*<audio[^>]*></audio>", "", html))
        subprocess.run(["npx", "--yes", "hyperframes@0.9.9", "render", "--format", "png-sequence", "-o", str(frames), "--quiet"], cwd=proj, env=env, check=True)
    finally:
        shutil.move(backup, index)

    # 2. sound
    mix = np.zeros((int(SR * dur) + SR, 2), np.float32)
    cache = {}
    tmp = Path(tempfile.mkdtemp())
    for m in re.finditer(r"<audio ([^>]*)>", html):
        a = dict(re.findall(r'([\w-]+)="([^"]*)"', m.group(1)))
        src = a["src"]
        if src not in cache:
            wav = tmp / f"{len(cache)}.wav"
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(proj / src), "-ac", "2", "-ar", str(SR), "-c:a", "pcm_s16le", str(wav)], env=env, check=True)
            w = wave.open(str(wav))
            cache[src] = np.frombuffer(w.readframes(w.getnframes()), np.int16).reshape(-1, 2).astype(np.float32) / 32768
        s0 = int(float(a.get("data-media-start", 0)) * SR)
        x = cache[src][s0 : s0 + int(float(a.get("data-duration", dur)) * SR)].copy() * float(a.get("data-volume", 1))
        for key, ramp in (("data-fade-in", np.linspace), ("data-fade-out", None)):
            n = min(len(x), int(float(a.get(key, 0)) * SR))
            if n:
                x[:n] *= np.linspace(0, 1, n)[:, None] if ramp else 1
                if not ramp:
                    x[-n:] *= np.linspace(1, 0, n)[:, None]
        at = int(float(a.get("data-start", 0)) * SR)
        mix[at : at + len(x)] += x[: len(mix) - at]
    mix = mix[: int(SR * dur)]
    peak = float(np.abs(mix).max())
    if peak > 0.98:
        mix *= 0.98 / peak
    wav = tmp / "mix.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((mix * 32767).astype("<i2").tobytes())

    # 3. encode
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-framerate", "30", "-i", str(frames / "frame_%06d.png"), "-i", str(wav),
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "12" if hq else "16", "-preset", "slow" if hq else "medium",
         "-c:a", "aac", "-b:a", "320k" if hq else "256k", "-movflags", "+faststart", "-shortest", str(out)],
        env=env, check=True,
    )
    shutil.rmtree(frames, ignore_errors=True)
    print(f"{out} ({dur:.1f} s, mix peak {peak:.2f})")


if __name__ == "__main__":
    main()
