#!/usr/bin/env python3
"""Turn AI-generated (or recorded) music and voice files into app-ready audio.

Drop files in Sounds/ using the names from design/sound-prompts.md:
    Sounds/music/<id>.(mp3|wav|m4a|aiff)
    Sounds/voice/<nono|fofo>/<id>.(mp3|wav|m4a|aiff)

For each file: decode (macOS afconvert), trim silence, level the volume,
make music loop seamlessly (crossfade the end into the start), and encode AAC.

Run:  tools/.venv/bin/python tools/audio/process_audio.py
Out:  app/assets/audio/music/<id>.m4a
      assets/audio/voice/<name>/<id>.m4a
      assets/audio/manifest.json  ("music" and "voice" sections; missing files listed as status "missing")
"""
import glob
import json
import os
import subprocess
import tempfile
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "Sounds")
OUT = os.path.join(ROOT, "app", "assets", "audio")
MANIFEST = os.path.join(OUT, "manifest.json")

# Keep in sync with design/sound-prompts.md.
MUSIC = {
    "map_theme": "Egypt map / home screen",
    "place_grandpa_house": "Grandpa's house",
    "place_nile": "The Nile & the felucca",
    "place_village": "The village",
    "place_pyramids": "The Pyramids",
    "place_monastery": "The desert monastery",
    "place_alexandria": "Alexandria & the sea",
    "game_loop_1": "Board games (Ludo, Snakes & Ladders, Connect 4)",
    "game_loop_2": "Catch & tap games (fishing, balloons, hit the word, frog)",
    "game_race": "Timed games (word race, tug of war, word train)",
}
VOICE = {
    "nono": {
        "yay": "Correct answer", "woohoo": "Level complete / celebrate", "giggle": "Wave, idle tap",
        "laugh": "Wins the game", "wow": "Star 3, new place", "uh_oh": "Wrong answer",
        "aww": "Level not passed", "gasp": "Surprised", "huh": "Confused", "pant": "After running",
        "yawn": "Sleep", "snore": "Sleep (idle too long)",
    },
    "fofo": {
        "yay": "Correct answer", "giggle": "Wave, idle tap", "laugh": "Wins the game",
        "wow": "Star 3, new place", "uh_oh": "Wrong answer", "aww": "Level not passed",
        "gasp": "Surprised", "hmm": "Thinking / hint", "aha": "Hint revealed",
        "yawn": "Sleep", "snore": "Sleep (idle too long)",
    },
}

MUSIC_RMS_DB = -19.0       # music sits under the effects
VOICE_LOUD_DB = -12.0      # short-term loudness, matches the sfx (-11 dB) closely
LOOP_XFADE = 2.0           # seconds
VOICE_MAX_LEN = 3.0        # seconds; reactions must stay snappy
VOICE_TWO_PART = {"uh_oh", "aha", "woohoo"}            # syllables can have a short pause between them
VOICE_KEEP_ALL = {"pant", "snore", "laugh", "giggle"}   # naturally made of several bursts
EXTS = ("mp3", "wav", "m4a", "aiff", "aif", "aac", "flac", "ogg")


def find_source(folder, sid):
    for ext in EXTS:
        hits = glob.glob(os.path.join(folder, f"{sid}.{ext}")) + glob.glob(os.path.join(folder, f"{sid}.{ext.upper()}"))
        if hits:
            return hits[0]
    return None


def decode(path, tmp, channels):
    wav = os.path.join(tmp, "in.wav")
    subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", str(channels), path, wav],
                   check=True, capture_output=True)
    with wave.open(wav) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(float) / 32768
        return x.reshape(-1, w.getnchannels()), w.getframerate()


def encode(x, sr, dest, bitrate):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "out.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(x.shape[1])
            w.setsampwidth(2)
            w.setframerate(sr)
            w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
        subprocess.run(["afconvert", "-f", "m4af", "-d", "aac", "-b", str(bitrate), wav, dest],
                       check=True, capture_output=True)


def trim(x, thresh_db, ends=(True, True), pad=0.02, sr=44100):
    level = np.max(np.abs(x), axis=1)
    on = np.nonzero(level > np.max(level) * 10 ** (thresh_db / 20))[0]
    if not len(on):
        return x
    p = int(pad * sr)
    a = max(0, on[0] - p) if ends[0] else 0
    b = min(len(x), on[-1] + p) if ends[1] else len(x)
    return x[a:b]


def fade(x, sr, fin=0.005, fout=0.03):
    x = x.copy()
    a, b = int(fin * sr), int(fout * sr)
    x[:a] *= np.linspace(0, 1, a)[:, None]
    x[len(x) - b:] *= np.linspace(1, 0, b)[:, None]
    return x


def cut_fade_out(x, sr, drop_db=3.0):
    """If the track fades out, cut it where the level first drops drop_db below the body."""
    win = sr
    levels = np.array([np.mean(x[i:i + win] ** 2) for i in range(0, len(x) - win, win)])
    if len(levels) < 20:
        return x
    body = np.median(levels[5:-10])
    end = len(levels)
    while end > len(levels) - 15 and levels[end - 1] < body * 10 ** (-drop_db / 10):
        end -= 1
    return x[: end * win] if end < len(levels) else x


def make_loop(x, sr):
    """Crossfade the last LOOP_XFADE seconds into the start so it loops with no gap."""
    x = cut_fade_out(x, sr)
    n = int(LOOP_XFADE * sr)
    if len(x) < 4 * n:
        return x
    body, tail = x[:-n].copy(), x[-n:]
    t = np.linspace(0, np.pi / 2, n)[:, None]
    body[:n] = body[:n] * np.sin(t) + tail * np.cos(t)     # equal-power
    return body


def limit(x, ceiling=0.95):
    peak = np.max(np.abs(x))
    return x * (ceiling / peak) if peak > ceiling else x


def short_loudness(x, sr, win=0.05):
    k = int(win * sr)
    mono = np.mean(x, axis=1)
    if len(mono) <= k:
        return 10 * np.log10(np.mean(mono ** 2) + 1e-12)
    return 10 * np.log10(np.max(np.convolve(mono ** 2, np.ones(k) / k, mode="valid")) + 1e-12)


def process_music(sid, path):
    with tempfile.TemporaryDirectory() as tmp:
        x, sr = decode(path, tmp, 2)
    x = trim(x, -50, ends=(True, True), pad=0, sr=sr)
    x = make_loop(x, sr)
    rms = 10 * np.log10(np.mean(x ** 2) + 1e-12)
    x = limit(x * 10 ** ((MUSIC_RMS_DB - rms) / 20))
    encode(x, sr, os.path.join(OUT, "music", sid + ".m4a"), 128000)
    return len(x) / sr


def first_vocal(x, sr, gap=0.25, thresh_db=-30):
    """AI takes often repeat the sound ('yay… yay… yay'). Keep the first one:
    cut at the first silence longer than `gap` seconds."""
    k = sr // 50
    level = np.array([np.sqrt(np.mean(x[i:i + k] ** 2)) for i in range(0, len(x) - k, k)])
    on = level > level.max() * 10 ** (thresh_db / 20)
    started, quiet = False, 0
    for i, v in enumerate(on):
        if v:
            started, quiet = True, 0
        elif started:
            quiet += 1
            if quiet * k > gap * sr:
                return x[: (i - quiet + 1) * k + int(0.08 * sr)]
    return x


def process_voice(name, sid, path, dest=None):
    with tempfile.TemporaryDirectory() as tmp:
        x, sr = decode(path, tmp, 1)
    x = trim(x, -40, sr=sr)
    if sid not in VOICE_KEEP_ALL:
        x = first_vocal(x, sr, gap=0.45 if sid in VOICE_TWO_PART else 0.3)
    x = x[: int(VOICE_MAX_LEN * sr)]
    x = fade(x, sr, fout=0.15 if len(x) >= int(VOICE_MAX_LEN * sr) else 0.03)
    x = limit(x * 10 ** ((VOICE_LOUD_DB - short_loudness(x, sr)) / 20))
    encode(x, sr, dest or os.path.join(OUT, "voice", name, sid + ".m4a"), 96000)
    return len(x) / sr


def main():
    music, voice = {}, {}
    for sid, desc in MUSIC.items():
        src = find_source(os.path.join(SRC, "music"), sid)
        entry = {"file": f"music/{sid}.m4a", "desc": desc, "loop": True, "status": "missing"}
        if src:
            entry.update(status="ready", duration=round(process_music(sid, src), 1), source=os.path.relpath(src, ROOT))
            print(f"music  {sid:22s} {entry['duration']:6.1f}s")
        music[sid] = entry
    for name, items in VOICE.items():
        voice[name] = {}
        for sid, desc in items.items():
            src = find_source(os.path.join(SRC, "voice", name), sid)
            entry = {"file": f"voice/{name}/{sid}.m4a", "desc": desc, "status": "missing"}
            takes = sorted(glob.glob(os.path.join(SRC, "voice", "takes", name, f"{sid}_*.mp3")))
            if takes:   # alternatives from generate_voices.py, processed the same way for the sound board
                entry["takes"] = []
                for t in takes:
                    prev = os.path.join(SRC, "voice", "preview", name, os.path.basename(t)[:-4] + ".m4a")
                    if not os.path.exists(prev) or os.path.getmtime(prev) < os.path.getmtime(t):
                        process_voice(name, sid, t, prev)
                    entry["takes"].append(os.path.relpath(prev, ROOT))
            if src:
                entry.update(status="ready", duration=round(process_voice(name, sid, src), 2), source=os.path.relpath(src, ROOT))
                print(f"voice  {name}/{sid:16s} {entry['duration']:5.2f}s")
            voice[name][sid] = entry

    manifest = {}
    if os.path.exists(MANIFEST):
        with open(MANIFEST) as f:
            manifest = json.load(f)
    manifest.update(version=1, music=music, voice=voice)
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    missing = [k for k, v in music.items() if v["status"] == "missing"]
    missing += [f"{n}/{k}" for n, items in voice.items() for k, v in items.items() if v["status"] == "missing"]
    print(f"missing {len(missing)}: {', '.join(missing) if missing else 'none'}")


if __name__ == "__main__":
    main()
