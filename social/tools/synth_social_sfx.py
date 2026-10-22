#!/usr/bin/env python3
"""Synthesize the motion-graphics sound effects used only by the social videos.

The app's own SFX (app/assets/audio/sfx) are reused as they are; this script
adds the extra "video" sounds (whooshes, keyword pops, logo sting...) that the
app doesn't need, built with the same DSP kit (tools/audio/dsp.py) so they
sound like one family.

Run:  tools/.venv/bin/python social/tools/synth_social_sfx.py [id ...]
Out:  social/assets/sfx/<id>.wav  (44.1 kHz mono 16-bit)
      social/assets/manifest.json  ("sfx" section, keeping entries with a "source"; other sections untouched)
"""
import json
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools", "audio"))

from dsp import (Mix, SR, arp, bell, boing, chime, chord, click, doum, finish, glass, marimba,  # noqa: E402
                 noise, osc, perc, svf, pluck, pop, reverb, slide_whistle, sparkle, sweep, tek, thud, whoosh,
                 wood, write_wav)

OUT = os.path.join(ROOT, "social", "assets", "sfx")
MANIFEST = os.path.join(ROOT, "social", "assets", "manifest.json")

SOUNDS = {}


def sfx(sid, desc, vol=0.8):
    def deco(fn):
        SOUNDS[sid] = dict(fn=fn, desc=desc, vol=vol)
        return fn
    return deco


# ================================================================ transitions

@sfx("mg_whoosh_in", "Character / big element flies in: airy whoosh up", 0.7)
def _():
    return reverb(whoosh(0.32, 300, 3200, q=1.2), 0.1)


@sfx("mg_whoosh_out", "Element flies out: whoosh down", 0.6)
def _():
    return whoosh(0.28, 3000, 350, q=1.2)


@sfx("mg_scene_swipe", "Scene change wipe: fast swish + soft tick", 0.6)
def _():
    return Mix().add(whoosh(0.2, 900, 5000, q=0.9)).add(wood("A6", 0.08), 0.15, 0.5).out()


# ================================================================ text & keywords

@sfx("mg_keyword_pop", "Keyword card pops in: bubbly pop + bright ding", 0.75)
def _():
    m = Mix().add(pop(520, 0.1)).add(marimba("E6", 0.45), 0.04, 0.7).add(glass(3100, 0.3), 0.05, 0.25)
    return reverb(m.out(), 0.12)


@sfx("mg_keyword_pop_2", "Keyword pop (variant 2): higher pop + chime", 0.75)
def _():
    m = Mix().add(pop(680, 0.1)).add(chime("G6", 0.5), 0.04, 0.6)
    return reverb(m.out(), 0.12)


@sfx("mg_word_tick", "Caption word lights up: tiny soft tick", 0.35)
def _():
    return wood("C7", 0.05)


# ================================================================ character motion

@sfx("mg_boing", "Character bounces / lands: cartoon boing", 0.7)
def _():
    return boing(160, 380, 0.4, wobble=0.2)


@sfx("mg_pose_swap", "Character changes pose: quick 'fwip'", 0.55)
def _():
    return Mix().add(osc(sweep(500, 1400, 0.07, "fast"), 0.07) * perc(0.07, 0.001, 0.03)).add(click(0.03), 0.0, 0.4).out()


@sfx("mg_slide_up", "Something rises up: slide whistle up", 0.6)
def _():
    return slide_whistle(500, 1300, 0.35)


@sfx("mg_slide_down", "Something drops: slide whistle down", 0.6)
def _():
    return slide_whistle(1300, 450, 0.35)


@sfx("mg_boom", "Cartoon crash: big soft thump, papery crash, then the letters' shimmer", 0.85)
def _():
    d = 0.9
    crash = svf(noise(d), 2400, q=0.6, mode="lp") * perc(d, 0.002, 0.16)
    m = Mix().add(thud(55, 0.55)).add(thud(90, 0.35), 0.02, 0.6).add(crash, 0.0, 0.7)
    m.add(wood("D5", 0.12), 0.05, 0.5).add(wood("A4", 0.12), 0.11, 0.4)
    m.add(sparkle(0.8, 10, start=0.18, gain=0.4))
    return reverb(m.out(), 0.2)


@sfx("mg_skid", "Cartoon skid stop: squeaky sneaker slide", 0.6)
def _():
    d = 0.35
    squeak = osc(np.linspace(1900, 1500, int(SR * d)), d, "tri", vib=0.04, vib_rate=38) * perc(d, 0.005, 0.2)
    rub = svf(noise(d), 3000, q=2, mode="bp") * perc(d, 0.003, 0.12)
    return Mix().add(squeak, 0, 0.5).add(rub, 0, 0.6).out()


# ================================================================ branding

@sfx("mg_logo_sting", "End card: logo pops in with darbuka hit, qanun run and sparkles", 0.85)
def _():
    m = Mix().add(doum(), 0.0).add(tek(), 0.12, 0.6).add(pop(450, 0.12), 0.0, 0.6)
    arp(["C5", "E5", "G5", "C6", "E6", "G6"], 0.045, pluck, 0.7, 0.55, start=0.1, mix=m)
    m.add(chord(["C6", "E6", "G6"], chime, 1.3), 0.38, 0.5)
    m.add(sparkle(1.0, 12, start=0.38))
    return reverb(m.out(), 0.18)


@sfx("mg_sparkle", "Magic sparkle shimmer (stars, shining letters)", 0.55)
def _():
    return reverb(sparkle(0.7, 9, gain=0.5), 0.2)


@sfx("mg_ta_da", "Ta-da! short reveal (brass-free: marimba + bell)", 0.8)
def _():
    m = Mix().add(marimba("G5", 0.3)).add(marimba("C6", 0.8), 0.13)
    m.add(bell("C7", 1.0, tau=0.35, ratio=2.0, index=1.2), 0.13, 0.5).add(thud(80, 0.25), 0.13, 0.5)
    return reverb(m.out(), 0.15)


# ================================================================ render

def main(only):
    os.makedirs(OUT, exist_ok=True)
    entries = {}
    for sid, s in SOUNDS.items():
        path = os.path.join(OUT, sid + ".wav")
        if not only or sid in only:
            x = finish(np.asarray(s["fn"](), float), s["vol"])
            write_wav(path, x)
            print(f"{sid:18s} {len(x) / SR:5.2f}s")
        dur = os.path.getsize(path) / 2 / SR if os.path.exists(path) else 0
        entries[sid] = {"file": f"sfx/{sid}.wav", "desc": s["desc"], "duration": round(dur, 2)}

    manifest = {}
    if os.path.exists(MANIFEST):
        with open(MANIFEST) as f:
            manifest = json.load(f)
    manifest["version"] = 1
    # keep sounds that weren't synthesized here (e.g. ElevenLabs SFX, "source" set)
    for sid, e in manifest.get("sfx", {}).items():
        if sid not in entries and e.get("source"):
            entries[sid] = e
    manifest["sfx"] = entries
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"{len(entries)} sounds -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main(set(sys.argv[1:]))
