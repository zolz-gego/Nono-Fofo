#!/usr/bin/env python3
"""Generate the brothers' voice sounds with the ElevenLabs Sound Effects API.

Prompts are read from design/elevenlabs-prompts.md (Part 2), so edit them there.
Each sound gets several takes in Sounds/voice/takes/<name>/<id>_<n>.mp3; take 1
is copied to Sounds/voice/<name>/<id>.mp3 unless you already picked one.
Pick a different take on the sound board, or copy it over by hand.

Run (asks for your API key with hidden input, or uses $ELEVENLABS_API_KEY; nothing is saved):
    tools/.venv/bin/python tools/audio/generate_voices.py            # all missing sounds
    tools/.venv/bin/python tools/audio/generate_voices.py nono/yay   # only these (regenerates)
    tools/.venv/bin/python tools/audio/generate_voices.py --takes 4
Then:  tools/.venv/bin/python tools/audio/process_audio.py
"""
import argparse
import json
import os
import re
import shutil
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PROMPTS = os.path.join(ROOT, "design", "elevenlabs-prompts.md")
VOICE = os.path.join(ROOT, "Sounds", "voice")
TAKES = os.path.join(VOICE, "takes")
API = "https://api.elevenlabs.io/v1/sound-generation"


def read_prompts():
    """{(name, id): prompt} from the '### Nono' / '### Fofo' sections."""
    text = open(PROMPTS, encoding="utf-8").read()
    part2 = text.split("## Part 2", 1)[1]
    prompts = {}
    for section in re.split(r"^### ", part2, flags=re.M)[1:]:
        name = section.split()[0].lower()
        for sid, prompt in re.findall(r"\*\*`(\w+)\.mp3`\*\*\s*```\s*\n(.*?)\n```", section, flags=re.S):
            prompts[(name, sid)] = prompt.strip()
    return prompts


def generate(key, prompt, dest):
    body = json.dumps({"text": prompt, "prompt_influence": 0.7}).encode()
    req = urllib.request.Request(API, data=body, method="POST", headers={
        "xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        f.write(r.read())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("only", nargs="*", help="e.g. nono/yay fofo/hmm (regenerates these)")
    ap.add_argument("--takes", type=int, default=3)
    args = ap.parse_args()

    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key or key == "paste-your-key-here":
        import getpass
        key = getpass.getpass("Paste your ElevenLabs API key (hidden) and press Enter: ").strip()
    if not key:
        sys.exit("No API key given.")

    prompts = read_prompts()
    if args.only:
        todo = [k for k in prompts if f"{k[0]}/{k[1]}" in args.only]
        unknown = set(args.only) - {f"{n}/{s}" for n, s in todo}
        if unknown:
            sys.exit(f"Unknown: {', '.join(sorted(unknown))}")
    else:
        todo = [k for k in prompts if not any(
            os.path.exists(os.path.join(VOICE, k[0], f"{k[1]}.{e}")) for e in ("mp3", "wav", "m4a"))]
    print(f"{len(todo)} sounds x {args.takes} takes")

    for name, sid in todo:
        os.makedirs(os.path.join(TAKES, name), exist_ok=True)
        os.makedirs(os.path.join(VOICE, name), exist_ok=True)
        for n in range(1, args.takes + 1):
            dest = os.path.join(TAKES, name, f"{sid}_{n}.mp3")
            try:
                generate(key, prompts[(name, sid)], dest)
            except urllib.error.HTTPError as e:
                sys.exit(f"ElevenLabs error {e.code} on {name}/{sid}: {e.read().decode(errors='replace')[:300]}")
            print(f"  {name}/{sid} take {n}")
        chosen = os.path.join(VOICE, name, f"{sid}.mp3")
        if args.only or not os.path.exists(chosen):
            shutil.copy(os.path.join(TAKES, name, f"{sid}_1.mp3"), chosen)

    print("Done. Now run: tools/.venv/bin/python tools/audio/process_audio.py")


if __name__ == "__main__":
    main()
