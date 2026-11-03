"""Whiteboard letter videos: one ElevenLabs take with character timestamps.

Builds the narration from every `say` in social/videos/<id>/whiteboard.json
(in board order), writes voice/take.mp3 and
voice/take.json (the text plus the start/end second of every character), which
the whiteboard engine (tools/whiteboard-hf) uses to place each line and time the pen.

The key comes from social/.env (ELEVENLABS_API_KEY). A take costs credits, so
this refuses to overwrite an existing take unless --force is given.

Run (from the repo root): python3 social/tools/wb_tts.py wb-01-alpha-ar [--force]
"""

import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

SOCIAL = Path(__file__).resolve().parents[1]

# Narrator per language (Arabic only for now) (ElevenLabs voice ids).
VOICES = {
    "ar": "vWDp3PLsTWjIhBxxUKh9",  # Fatima - Smooth Audiobook Narrator (Egyptian)
}
MODEL = "eleven_multilingual_v2"


def api_key() -> str:
    if os.environ.get("ELEVENLABS_API_KEY"):
        return os.environ["ELEVENLABS_API_KEY"]
    for line in (SOCIAL / ".env").read_text().splitlines():
        if line.startswith("ELEVENLABS_API_KEY="):
            return line.split("=", 1)[1].strip()
    sys.exit("ELEVENLABS_API_KEY missing from social/.env")


def narration(spec: dict) -> str:
    lines = list(spec["intro"]["say"]) + [f["say"] for f in spec.get("facts", [])]
    for sec in spec["sections"]:
        lines.append(" ".join([sec["say"]] + [w["say"] for w in sec["words"]]))
    lines += [spec["recap"]["say"], spec["end"]["say"]]
    return "\n".join(lines)


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        sys.exit(__doc__)
    folder = SOCIAL / "videos" / args[0]
    lang = args[0].rsplit("-", 1)[-1]
    voice = VOICES.get(lang) or sys.exit(f"no narrator voice for '{lang}'")
    out = folder / "voice"
    out.mkdir(exist_ok=True)
    if (out / "take.mp3").exists() and "--force" not in sys.argv:
        sys.exit(f"{out / 'take.mp3'} exists (use --force to spend credits on a new take)")

    text = narration(json.loads((folder / "whiteboard.json").read_text()))
    body = {
        "text": text,
        "model_id": MODEL,
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.8, "style": 0.25, "speed": 0.88},
    }
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice}/with-timestamps?output_format=mp3_44100_192",
        data=json.dumps(body).encode(),
        headers={"xi-api-key": api_key(), "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as r:
        d = json.load(r)
    (out / "take.mp3").write_bytes(base64.b64decode(d["audio_base64"]))
    a = d["alignment"]
    (out / "take.json").write_text(
        json.dumps(
            {
                "text": "".join(a["characters"]),
                "start": a["character_start_times_seconds"],
                "end": a["character_end_times_seconds"],
            },
            ensure_ascii=False,
        )
    )
    print(f"take -> {out / 'take.mp3'} ({a['character_end_times_seconds'][-1]:.1f}s, {len(text)} chars)")


if __name__ == "__main__":
    main()
