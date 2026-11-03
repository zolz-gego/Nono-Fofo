"""Release a whiteboard letter video (HyperFrames): everything that gets posted.

    tools/.venv/bin/python social/tools/wb_release.py <folder> --thumb <seconds> [--story-until "<phrase>"] [--story <seconds>]

Writes social/out/release/<folder>/:
  video.mp4      the full video, release quality (H.264 CRF 12 slow, AAC 320k)
  thumbnail.jpg  the frame at --thumb seconds, full size
  story.mp4      the hook for the story: the video's opening, ending 0.4 s after
                 --story-until (a phrase of the narration, e.g. a question that
                 leaves them curious), or at --story seconds (default 10), audio faded out
post.md (the TikTok and Instagram captions) is written by hand next to them (see the skill).
"""

import json
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


def ff(*args):
    subprocess.run([str(FF / "ffmpeg"), "-v", "error", "-y", *map(str, args)], env=ENV, check=True)


def opt(name, default=None):
    return sys.argv[sys.argv.index(name) + 1] if name in sys.argv else default


def story_end(folder: str, phrase: str) -> float:
    """Video time just after `phrase` is spoken."""
    take = json.loads((SOCIAL / "videos" / folder / "voice" / "take.json").read_text())
    timing = json.loads((SOCIAL / "hyperframes" / folder / "timing.json").read_text())
    i = take["text"].index(phrase)
    t_end = take["end"][i + len(phrase) - 1]
    line = take["text"][:i].count("\n")  # the say this phrase is in
    a0 = take["lines"][line][0]
    return timing["clips"][line]["start"] + (t_end - a0) + 0.4


def main() -> None:
    if len(sys.argv) < 2 or "--thumb" not in sys.argv:
        sys.exit(__doc__)
    folder = sys.argv[1]
    out = SOCIAL / "out" / "release" / folder
    out.mkdir(parents=True, exist_ok=True)
    py = ROOT / "tools" / ".venv" / "bin" / "python"
    subprocess.run(["node", str(SOCIAL / "tools" / "wb_hyperframes.mjs"), folder], check=True)
    subprocess.run([str(py), str(SOCIAL / "tools" / "hf_render.py"), str(SOCIAL / "hyperframes" / folder), str(out / "video.mp4"), "--hq"], check=True)

    video = out / "video.mp4"
    ff("-ss", opt("--thumb"), "-i", video, "-frames:v", "1", "-q:v", "1", out / "thumbnail.jpg")

    end = story_end(folder, opt("--story-until")) if "--story-until" in sys.argv else float(opt("--story", 10))
    tmp = Path(tempfile.mkdtemp())
    ff("-i", video, "-t", end, "-ac", "2", "-ar", 48000, "-c:a", "pcm_s16le", tmp / "a.wav")
    w = wave.open(str(tmp / "a.wav"))
    x = np.frombuffer(w.readframes(w.getnframes()), np.int16).reshape(-1, 2).astype(np.float32)
    n = min(len(x), int(0.5 * 48000))
    x[-n:] *= np.linspace(1, 0, n)[:, None]
    with wave.open(str(tmp / "b.wav"), "wb") as o:
        o.setnchannels(2)
        o.setsampwidth(2)
        o.setframerate(48000)
        o.writeframes(x.astype("<i2").tobytes())
    ff("-i", video, "-i", tmp / "b.wav", "-map", "0:v", "-map", "1:a", "-t", end, "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", 12, "-preset", "slow",
       "-c:a", "aac", "-b:a", "320k", "-movflags", "+faststart", out / "story.mp4")
    print(f"release -> {out} (story {end:.1f} s); now write post.md")


if __name__ == "__main__":
    main()
