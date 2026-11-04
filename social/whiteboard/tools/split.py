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
        out += [sec["say"]] + [w["say"] for w in sec["words"]]
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
    import mlx_whisper

    folder = WHITEBOARD / "videos" / sys.argv[1]
    spec = json.loads((folder / "whiteboard.json").read_text())
    lines = says(spec)
    x = load(folder / "voice" / "full.mp3")
    dur = len(x) / 16000
    r = mlx_whisper.transcribe(x, path_or_hf_repo="mlx-community/whisper-large-v3-turbo", language="ar", word_timestamps=True)

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

    # take.json: the narration text with times spread over each line's span
    text, start, end = "", [], []
    for i, (l, (a0, a1)) in enumerate(zip(lines, spans)):
        sep = "" if i == 0 else "\n"
        for c in sep:
            text += c
            start.append(a0)
            end.append(a0)
        n = len(l)
        for k, c in enumerate(l):
            text += c
            start.append(a0 + (a1 - a0) * k / n)
            end.append(a0 + (a1 - a0) * (k + 1) / n)
    shutil.copyfile(folder / "voice" / "full.mp3", folder / "voice" / "take.mp3")
    (folder / "voice" / "take.json").write_text(json.dumps({"text": text, "start": start, "end": end, "lines": spans}, ensure_ascii=False))
    for l, (a0, a1) in zip(lines, spans):
        print(f"{a0:6.2f}-{a1:6.2f}  {l}")


if __name__ == "__main__":
    main()
