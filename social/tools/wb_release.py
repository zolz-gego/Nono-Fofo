"""Release a whiteboard letter video (HyperFrames): everything that gets posted.

    tools/.venv/bin/python social/tools/wb_release.py <folder> --thumb <seconds> [--story-beats 0-4] [--speed 1.5] [--story-only]

Writes social/out/release/<folder>/:
  video.mp4      the full video, release quality (H.264 CRF 12 slow, AAC 320k)
  thumbnail.jpg  the frame at --thumb seconds, full size
  story.mp4      the hook for the story: the video's first beats (--story-beats,
                 indices of the `say` lines, default 0-4) with every silence cut
                 (only moments where the voice speaks, the pen draws or the camera
                 moves are kept), played --speed times faster (default 1.5; the
                 voice keeps its pitch), audio faded out at the end
--story-only re-makes story.mp4 from an existing video.mp4.
post.md (the TikTok and Instagram captions) is written by hand next to them (see the skill).
"""

import json
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SOCIAL = ROOT / "social"
FF = SOCIAL / "remotion" / "node_modules" / "@remotion" / "compositor-darwin-arm64"
ENV = {"DYLD_LIBRARY_PATH": str(FF), "PATH": "/usr/bin:/bin"}
SR = 48000
FPS = 30


def ff(*args):
    subprocess.run([str(FF / "ffmpeg"), "-v", "error", "-y", *map(str, args)], env=ENV, check=True)


def opt(name, default=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def read_wav(path):
    w = wave.open(str(path))
    x = np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768
    return x.reshape(-1, w.getnchannels())


def write_wav(path, x, sr=SR):
    with wave.open(str(path), "wb") as o:
        o.setnchannels(x.shape[1])
        o.setsampwidth(2)
        o.setframerate(sr)
        o.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())


def wsola(x, rate, sr=SR):
    """Speed audio up by `rate` keeping its pitch (waveform-similarity overlap-add)."""
    n = int(0.040 * sr)  # frame
    hop = n // 2  # output hop
    tol = int(0.012 * sr)  # search ± this for the best-matching frame
    win = np.hanning(n).astype(np.float32)[:, None]
    out_len = int(len(x) / rate) + n
    out = np.zeros((out_len, x.shape[1]), np.float32)
    norm = np.zeros((out_len, 1), np.float32)
    pad = np.vstack([np.zeros((tol, x.shape[1]), np.float32), x, np.zeros((n + tol * 2, x.shape[1]), np.float32)])
    prev = None
    o = 0
    while True:
        centre = int(o * rate)
        if centre >= len(x):
            break
        if prev is None:
            pos = centre
        else:
            # the frame near `centre` that best continues what was just written
            seg = pad[centre: centre + n + 2 * tol, 0]
            ref = prev[:, 0]
            corr = np.correlate(seg, ref, mode="valid")
            pos = centre - tol + int(np.argmax(corr))
        frame = pad[pos + tol: pos + tol + n]
        out[o: o + n] += frame * win
        norm[o: o + n] += win
        prev = pad[pos + tol + hop: pos + tol + hop + n]  # natural continuation of this frame
        o += hop
    return out[: int(len(x) / rate)] / np.maximum(norm[: int(len(x) / rate)], 1e-3)


def voice_activity(folder, timing, take):
    """Board-time intervals where the narrator is actually speaking."""
    voice = SOCIAL / "videos" / folder / "voice" / "take.mp3"
    tmp = Path(tempfile.mkdtemp()) / "v.wav"
    ff("-i", voice, "-ac", "1", "-ar", 16000, tmp)
    x = read_wav(tmp)[:, 0]
    hop = 160  # 10 ms
    e = np.sqrt(np.convolve(x ** 2, np.ones(hop * 2) / (hop * 2), mode="same")[::hop])
    db = 20 * np.log10(e + 1e-9)
    loud = db > db.max() - 34
    spans = []
    for clip, (a0, a1) in zip(timing["clips"], take["lines"]):
        i0, i1 = int(a0 * 100), int(a1 * 100)
        run = None
        for k in range(i0, min(i1, len(loud))):
            if loud[k] and run is None:
                run = k
            if (not loud[k] or k == i1 - 1) and run is not None:
                spans.append((clip["start"] + (run / 100 - a0), clip["start"] + (k / 100 - a0)))
                run = None
    return spans


def make_story(folder, out, beats, speed):
    timing = json.loads((SOCIAL / "hyperframes" / folder / "timing.json").read_text())
    take = json.loads((SOCIAL / "videos" / folder / "voice" / "take.json").read_text())
    chosen = [timing["beats"][i] for i in beats]
    t0 = 0.0
    t1 = max(max(b["voice"][1], b["draw"][1] if b["draw"] else 0) for b in chosen) + 0.15
    # keep: voice, drawing, camera moves
    keep = []
    keep += [s for s in voice_activity(folder, timing, take) if s[1] > t0 and s[0] < t1]
    for b in chosen:
        if b["draw"]:
            keep.append(tuple(b["draw"]))
        if b["cam"] is not None:
            keep.append((b["cam"], b["cam"] + 0.9))
    keep = sorted((max(t0, a - 0.06), min(t1, b + 0.08)) for a, b in keep)
    merged = []
    for a, b in keep:
        if merged and a <= merged[-1][1] + 0.12:  # close tiny gaps
            merged[-1][1] = max(merged[-1][1], b)
        else:
            merged.append([a, b])
    kept = sum(b - a for a, b in merged)

    tmp = Path(tempfile.mkdtemp())
    video = out / "video.mp4"
    # picture: decode the opening once, then pick frames along the kept time
    ff("-t", t1 + 0.2, "-i", video, tmp / "%05d.png")
    src = sorted(tmp.glob("*.png"))
    frames = tmp / "story"
    frames.mkdir()
    n_out = int(kept / speed * FPS)
    for j in range(n_out):
        k = j / FPS * speed  # kept time
        for a, b in merged:
            if k <= b - a:
                st = a + k
                break
            k -= b - a
        else:
            st = merged[-1][1]
        shutil.copyfile(src[min(len(src) - 1, int(round(st * FPS)))], frames / f"{j:05d}.png")

    # sound: the kept stretches of the mix, joined with short crossfades, sped up
    ff("-t", t1 + 0.2, "-i", video, "-ac", "2", "-ar", SR, "-c:a", "pcm_s16le", tmp / "a.wav")
    a = read_wav(tmp / "a.wav")
    xf = int(0.02 * SR)
    pieces = []
    for s, e in merged:
        p = a[int(s * SR): int(e * SR)].copy()
        p[:xf] *= np.linspace(0, 1, xf)[:, None]
        p[-xf:] *= np.linspace(1, 0, xf)[:, None]
        pieces.append(p)
    joined = pieces[0]
    for p in pieces[1:]:
        joined = np.vstack([joined[:-xf], joined[-xf:] + p[:xf], p[xf:]])
    fast = wsola(joined, speed)
    fade = int(0.35 * SR)
    fast[-fade:] *= np.linspace(1, 0, fade)[:, None]
    write_wav(tmp / "story.wav", fast)
    ff("-framerate", FPS, "-i", frames / "%05d.png", "-i", tmp / "story.wav", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", 12, "-preset", "slow",
       "-c:a", "aac", "-b:a", "320k", "-movflags", "+faststart", "-shortest", out / "story.mp4")
    shutil.rmtree(tmp, ignore_errors=True)
    return t1, kept, n_out / FPS


def main() -> None:
    if len(sys.argv) < 2 or ("--thumb" not in sys.argv and "--story-only" not in sys.argv):
        sys.exit(__doc__)
    folder = sys.argv[1]
    out = SOCIAL / "out" / "release" / folder
    out.mkdir(parents=True, exist_ok=True)
    if "--story-only" not in sys.argv:
        py = ROOT / "tools" / ".venv" / "bin" / "python"
        subprocess.run(["node", str(SOCIAL / "tools" / "wb_hyperframes.mjs"), folder], check=True)
        subprocess.run([str(py), str(SOCIAL / "tools" / "hf_render.py"), str(SOCIAL / "hyperframes" / folder), str(out / "video.mp4"), "--hq"], check=True)
        ff("-ss", opt("--thumb"), "-i", out / "video.mp4", "-frames:v", "1", "-q:v", "1", out / "thumbnail.jpg")
    lo, hi = map(int, opt("--story-beats", "0-4").split("-"))
    src, kept, length = make_story(folder, out, range(lo, hi + 1), float(opt("--speed", 1.5)))
    print(f"release -> {out}: story = the first {src:.1f} s, {kept:.1f} s kept, {length:.1f} s at {opt('--speed', 1.5)}x; now write post.md")


if __name__ == "__main__":
    main()
