#!/usr/bin/env python3
"""Synthesize all short sound effects for Nono & Fofo.

Bright cartoon style, gentle on mistakes (never harsh buzzers), with a light
Egyptian touch (qanun-like plucks, darbuka) in the fanfares. Sounds that kids
hear many times have several variants (correct_1..3 etc.) so the app can
rotate them.

Run:  tools/.venv/bin/python tools/audio/synth_sfx.py [id ...]
Out:  app/assets/audio/sfx/<id>.wav  (44.1 kHz mono 16-bit)
      assets/audio/manifest.json  ("sfx" section; other sections untouched)
"""
import json
import os
import sys

import numpy as np

from dsp import (Mix, SR, ahr, arp, bell, boing, brass, bubble, chime, chord, clack, click, doum,
                 finish, glass, hump, hz, impulses, marimba, noise, osc, perc, pluck, pop, reverb,
                 rng, slide_whistle, sparkle, svf, sweep, tek, thud, tone, tt, water, whoosh, wood,
                 write_wav)

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "app", "assets", "audio", "sfx")
MANIFEST = os.path.join(ROOT, "app", "assets", "audio", "manifest.json")

SOUNDS = {}


def sfx(sid, group, desc, vol=0.8):
    def deco(fn):
        SOUNDS[sid] = dict(fn=fn, group=group, desc=desc, vol=vol)
        return fn
    return deco


# ================================================================ UI

@sfx("ui_tap", "ui", "Button tap: soft bubble pop", 0.55)
def _():
    return pop(650, 0.08)


@sfx("ui_back", "ui", "Back / close: low pop going down", 0.5)
def _():
    return osc(sweep(620, 330, 0.09, "fast"), 0.09) * perc(0.09, 0.001, 0.03)


@sfx("ui_toggle", "ui", "Switch toggle: tick-tock", 0.5)
def _():
    return Mix().add(wood("E6", 0.08)).add(wood("A6", 0.08), 0.06).out()


@sfx("ui_open", "ui", "Popup opens: whoosh up + ding", 0.6)
def _():
    m = Mix().add(whoosh(0.22, 400, 2500, gain=0.5)).add(marimba("G5", 0.5), 0.15)
    return reverb(m.out(), 0.12)


@sfx("ui_close", "ui", "Popup closes: whoosh down + dong", 0.55)
def _():
    return Mix().add(whoosh(0.2, 2500, 400, gain=0.5)).add(marimba("C5", 0.4), 0.12).out()


@sfx("ui_swipe", "ui", "Page swipe", 0.45)
def _():
    return whoosh(0.18, 900, 4000, q=1.0)


@sfx("ui_locked", "ui", "Locked item: soft dun-dun", 0.6)
def _():
    return Mix().add(wood("C4", 0.2)).add(wood("C4", 0.2), 0.13).out()


@sfx("ui_unlock", "ui", "Unlock: key clink + rising bells", 0.7)
def _():
    m = Mix().add(glass(2600, 0.3), 0, 0.5).add(clack(3000), 0.05, 0.5)
    arp(["C6", "E6", "G6", "C7"], 0.06, chime, 0.8, 0.6, start=0.15, mix=m)
    return reverb(m.out(), 0.18)


@sfx("ui_select", "ui", "Pick a buddy / item: boop-bip", 0.6)
def _():
    return Mix().add(tone("G5", 0.07, "sine", 0.003, 0.03)).add(tone("D6", 0.12, "sine", 0.003, 0.08), 0.07).out()


@sfx("ui_coin", "ui", "Collect coin / sticker point", 0.55)
def _():
    m = Mix().add(tone("B5", 0.07, "square", 0.002, 0.01) * 0.6)
    m.add(osc("E6", 0.45, "square") * perc(0.45, 0.002, 0.15) * 0.6, 0.07)
    return m.out()


# ================================================================ feedback

def _correct(notes, step, top):
    m = Mix()
    arp(notes, step, marimba, 0.6, 1.0, mix=m)
    m.add(bell(top, 1.0, tau=0.35, ratio=1.41, index=1.0), step * len(notes), 0.7)
    m.add(sparkle(0.5, 6, start=step * len(notes)), 0, 0.8)
    return reverb(m.out(), 0.16)


@sfx("correct_1", "feedback", "Correct answer (variant 1): marimba arpeggio + bell", 0.85)
def _():
    return _correct(["C6", "E6", "G6"], 0.07, "C7")


@sfx("correct_2", "feedback", "Correct answer (variant 2)", 0.85)
def _():
    return _correct(["D6", "F#6", "A6"], 0.065, "D7")


@sfx("correct_3", "feedback", "Correct answer (variant 3): quick up-down", 0.85)
def _():
    return _correct(["G5", "C6", "E6", "G6"], 0.055, "E7")


@sfx("correct_streak", "feedback", "3 in a row! fast run up + party pop", 0.9)
def _():
    m = Mix()
    arp(["C6", "D6", "E6", "G6", "A6", "C7"], 0.045, marimba, 0.5, mix=m)
    m.add(pop(900, 0.1), 0.3, 0.8)
    m.add(sparkle(0.9, 14, start=0.3), 0, 1.0)
    m.add(chord(["C6", "E6", "G6"], chime, 1.2), 0.3, 0.8)
    return reverb(m.out(), 0.18)


@sfx("wrong_1", "feedback", "Wrong answer (variant 1): gentle cartoon 'bwoop' down", 0.65)
def _():
    m = Mix().add(tone(sweep("G4", "C4", 0.35, "exp"), 0.35, "tri", 0.01, 0.1, vib=0.02))
    m.add(wood("C4", 0.2), 0, 0.4)
    return m.out()


@sfx("wrong_2", "feedback", "Wrong answer (variant 2): two soft low boops", 0.65)
def _():
    m = Mix().add(tone("E4", 0.14, "tri", 0.005, 0.06)).add(tone("C4", 0.28, "tri", 0.005, 0.15, vib=0.015), 0.16)
    return m.out()


@sfx("try_again", "feedback", "Try again: hopeful two-note chime", 0.6)
def _():
    return reverb(Mix().add(chime("D5", 0.6)).add(chime("G5", 0.9), 0.15).out(), 0.15)


@sfx("hint", "feedback", "Hint appears: magic twinkle sweep", 0.75)
def _():
    m = Mix()
    m.add(osc(sweep(1200, 3200, 0.6), 0.6, vib=0.02, vib_rate=18) * hump(0.6) * 0.15)
    m.add(sparkle(0.8, 12, ("E6", "G6", "A6", "C7", "D7", "E7")))
    m.add(chime("A6", 0.9), 0.45, 0.4)
    return reverb(m.out(), 0.25, tau=0.35)


@sfx("skip_turn", "feedback", "Turn skipped: swoosh away + slide down", 0.6)
def _():
    m = Mix().add(whoosh(0.3, 3000, 600, gain=0.6)).add(slide_whistle("C6", "G5", 0.3) * 0.5, 0.05)
    return m.out()


@sfx("your_turn", "feedback", "Your turn: ding-dong up", 0.65)
def _():
    return reverb(Mix().add(chime("G5", 0.6)).add(chime("C6", 0.9), 0.18).out(), 0.15)


@sfx("opponent_turn", "feedback", "Nono/Fofo's turn: marimba dong-ding", 0.55)
def _():
    return Mix().add(marimba("E5", 0.4)).add(marimba("C5", 0.6), 0.16).out()


@sfx("timer_tick", "feedback", "Clock tick", 0.45)
def _():
    return wood("A5", 0.08)


@sfx("timer_hurry", "feedback", "Hurry! fast high ticks", 0.55)
def _():
    m = Mix()
    for i in range(4):
        m.add(wood("E6" if i % 2 else "A6", 0.07), i * 0.11)
    return m.out()


@sfx("time_up", "feedback", "Time's up: cuckoo", 0.6)
def _():
    return Mix().add(tone("E6", 0.18, "sine", 0.01, 0.05)).add(tone("C6", 0.3, "sine", 0.01, 0.12), 0.22).out()


@sfx("countdown_beep", "feedback", "3-2-1 beep", 0.55)
def _():
    return tone("A5", 0.15, "square", 0.003, 0.05) * 0.6


@sfx("countdown_go", "feedback", "GO! high beep + whoosh", 0.7)
def _():
    return Mix().add(tone("A6", 0.4, "square", 0.003, 0.2) * 0.6).add(whoosh(0.35, 600, 5000, gain=0.4), 0.02).out()


# ================================================================ level & rewards

@sfx("level_start", "level", "Level start: darbuka + qanun run + bell", 0.85)
def _():
    m = Mix()
    for at, hit in [(0, doum), (0.18, tek), (0.27, tek), (0.36, doum)]:
        m.add(hit(), at, 0.8)
    arp(["C5", "E5", "G5", "C6", "E6"], 0.05, lambda f, d: pluck(f, d, 0.7), 0.9, 0.7, start=0.36, mix=m)
    m.add(bell("G6", 1.0, tau=0.4, ratio=1.41, index=1.0), 0.62, 0.5)
    return reverb(m.out(), 0.15)


@sfx("level_complete", "level", "Level complete! fanfare with darbuka roll + sparkles", 0.9)
def _():
    m = Mix()
    melody = [("C5", 0.0), ("E5", 0.12), ("G5", 0.24), ("C6", 0.36), ("G5", 0.6), ("C6", 0.72)]
    for nt, at in melody:
        m.add(marimba(nt, 0.7), at)
        m.add(pluck(nt, 0.7, 0.6), at, 0.5)
    for i in range(8):
        m.add(tek(), 0.36 + i * 0.045, 0.35 + 0.05 * i)
    m.add(doum(), 0.72, 1.0)
    m.add(chord(["C5", "E5", "G5", "C6"], lambda f, d: tone(f, d, "tri", 0.02, 0.6), 1.4), 0.72, 0.6)
    m.add(bell("C7", 1.5, tau=0.6, ratio=1.41, index=1.0), 0.72, 0.6)
    m.add(sparkle(1.2, 16), 0.75, 1.0)
    return reverb(m.out(), 0.18)


@sfx("level_failed", "level", "Level not passed: soft 'wah-wah' then a hopeful rise", 0.7)
def _():
    m = Mix()
    for i, (nt, d) in enumerate([("G4", 0.28), ("F#4", 0.28), ("F4", 0.28), ("E4", 0.8)]):
        m.add(brass(nt, d, vib=0.03 if i == 3 else 0.0), i * 0.3, 0.8)
    arp(["C5", "E5", "G5"], 0.09, chime, 0.9, 0.45, start=1.85, mix=m)
    return reverb(m.out(), 0.14)


def _star(note, big=False):
    m = Mix()
    m.add(whoosh(0.18, 1500, 6000, gain=0.35))
    m.add(bell(note, 1.1, tau=0.4, ratio=1.41, index=1.3), 0.12)
    m.add(glass(hz(note) * 2, 0.5), 0.12, 0.25)
    m.add(sparkle(0.6 if big else 0.4, 12 if big else 6, start=0.12), 0, 0.8)
    if big:
        m.add(chord(["C6", "E6", "G6", "C7"], chime, 1.3), 0.12, 0.6)
    return reverb(m.out(), 0.2)


@sfx("star_1", "level", "First star lands", 0.75)
def _():
    return _star("E6")


@sfx("star_2", "level", "Second star (higher)", 0.8)
def _():
    return _star("G6")


@sfx("star_3", "level", "Third star (highest, extra shine)", 0.9)
def _():
    return _star("C7", big=True)


@sfx("letter_found", "level", "Lost letter found: harp glissando + bell", 0.85)
def _():
    m = Mix()
    scale = ["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6", "G6", "A6", "C7"]
    arp(scale, 0.035, lambda f, d: pluck(f, d, 0.8), 1.0, 0.5, mix=m)
    m.add(bell("E7", 1.4, tau=0.5, ratio=1.41, index=1.0), 0.4, 0.6)
    m.add(sparkle(0.8, 10, start=0.4), 0, 0.8)
    return reverb(m.out(), 0.25, tau=0.35)


@sfx("place_unlocked", "level", "New map place unlocked: harp up + bell chord + darbuka", 0.9)
def _():
    m = Mix()
    scale = ["G4", "A4", "C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6"]
    arp(scale, 0.04, lambda f, d: pluck(f, d, 0.7), 1.0, 0.5, mix=m)
    m.add(doum(), 0.42).add(tek(), 0.6, 0.6).add(doum(), 0.72)
    m.add(chord(["C6", "E6", "G6", "C7"], lambda f, d: bell(f, d, tau=0.6, ratio=1.41, index=1.0), 1.8), 0.42, 0.7)
    m.add(sparkle(1.0, 14, start=0.45), 0, 0.9)
    return reverb(m.out(), 0.22, tau=0.35)


@sfx("reward_sticker", "level", "Sticker reward: peel + slap + sparkle", 0.75)
def _():
    m = Mix().add(whoosh(0.2, 2000, 7000, q=3, gain=0.4)).add(thud(160, 0.15), 0.2, 0.6).add(click(0.03, 2500), 0.2)
    m.add(sparkle(0.5, 6, start=0.22))
    return reverb(m.out(), 0.12)


@sfx("confetti", "level", "Confetti party pops", 0.8)
def _():
    m = Mix()
    for i in range(7):
        m.add(pop(rng.uniform(500, 1100), 0.09), i * 0.07 + rng.uniform(0, 0.03), rng.uniform(0.5, 1.0))
    m.add(osc(sweep(320, 560, 0.5), 0.5, "saw") * ahr(0.5, 0.02, 0.1) * 0.15, 0.05)  # party horn
    m.add(sparkle(0.9, 12, start=0.2))
    return reverb(m.out(), 0.15)


# ================================================================ characters

@sfx("char_run", "character", "Nono runs in: quick cartoon footsteps", 0.6)
def _():
    m = Mix()
    for i in range(10):
        m.add(wood(380 if i % 2 else 460, 0.06), i * 0.075, 0.7)
    m.add(whoosh(0.8, 300, 1200, gain=0.2))
    return m.out()


@sfx("char_dash", "character", "Zoom across the screen", 0.6)
def _():
    return Mix().add(whoosh(0.35, 400, 4500, q=2.0)).add(slide_whistle("C6", "C7", 0.25) * 0.3, 0.05).out()


@sfx("char_jump", "character", "Jump: boing up", 0.6)
def _():
    return boing(200, 520, 0.4)


@sfx("char_land", "character", "Land: soft thump", 0.6)
def _():
    return thud(80, 0.25)


@sfx("char_think", "character", "Fofo thinks: rising thought bubbles", 0.55)
def _():
    m = Mix()
    for i, f in enumerate([420, 520, 650]):
        m.add(bubble(f, 0.1), i * 0.16)
    m.add(chime("E6", 0.6), 0.5, 0.3)
    return reverb(m.out(), 0.15)


@sfx("char_surprise", "character", "Surprise: quick slide-whistle 'fwip!'", 0.6)
def _():
    return slide_whistle("C5", "C7", 0.22, curve="exp")


@sfx("char_appear", "character", "Character pops in", 0.6)
def _():
    return reverb(Mix().add(pop(500, 0.1)).add(sparkle(0.3, 4), 0.03).out(), 0.12)


# ================================================================ connect 4

@sfx("c4_drop", "connect4", "Disc falls down the column", 0.65)
def _():
    m = Mix().add(slide_whistle("A6", "C6", 0.22) * 0.25).add(whoosh(0.22, 2500, 700, gain=0.3))
    m.add(clack(1800, 0.1), 0.22).add(clack(2100, 0.07), 0.29, 0.4)
    return m.out()


@sfx("c4_land", "connect4", "Disc clacks into place", 0.6)
def _():
    return Mix().add(clack(1800, 0.1)).add(clack(2100, 0.07), 0.07, 0.4).out()


@sfx("c4_column_full", "connect4", "Column is full: dull thunk", 0.55)
def _():
    return Mix().add(thud(110, 0.2)).add(wood("D4", 0.15), 0, 0.4).out()


@sfx("c4_win_line", "connect4", "Four in a row! 4 rising clicks + sparkle", 0.85)
def _():
    m = Mix()
    for i, nt in enumerate(["C6", "E6", "G6", "C7"]):
        m.add(clack(2000 + 300 * i, 0.08), i * 0.12, 0.6).add(bell(nt, 0.6, tau=0.25, ratio=1.41), i * 0.12, 0.5)
    m.add(sparkle(0.7, 10, start=0.45))
    return reverb(m.out(), 0.18)


@sfx("c4_reset", "connect4", "Board empties: disc cascade", 0.65)
def _():
    m = Mix()
    for i in range(18):
        m.add(clack(rng.uniform(1500, 2600), 0.07), i * 0.04 + rng.uniform(0, 0.02), rng.uniform(0.3, 0.8))
    return m.out()


# ================================================================ dice & board games

@sfx("dice_shake", "board", "Shake the dice in a cup", 0.6)
def _():
    d = 0.6
    clicks = impulses(d, 25, 25, jitter=0.5)
    m = Mix().add(svf(clicks, 2500, q=3, mode="bp") * 4 * hump(d))
    return m.out()


@sfx("dice_roll", "board", "Dice tumble and stop", 0.7)
def _():
    m = Mix()
    at, gap = 0.0, 0.05
    for i in range(10):
        m.add(clack(rng.uniform(1700, 2600), 0.08), at, 1.0 - i * 0.06)
        at += gap
        gap *= 1.22
    m.add(clack(2000, 0.1), at + 0.05, 0.6)
    return m.out()


@sfx("dice_land", "board", "Dice result shown: clack + ding", 0.65)
def _():
    return Mix().add(clack(2100)).add(chime("G6", 0.5), 0.05, 0.4).out()


@sfx("piece_hop_1", "board", "Piece hops one square (low)", 0.5)
def _():
    return Mix().add(wood("C6", 0.1)).add(boing(500, 800, 0.12, 0.05) * 0.3).out()


@sfx("piece_hop_2", "board", "Piece hops one square (mid)", 0.5)
def _():
    return Mix().add(wood("E6", 0.1)).add(boing(600, 950, 0.12, 0.05) * 0.3).out()


@sfx("piece_hop_3", "board", "Piece hops one square (high)", 0.5)
def _():
    return Mix().add(wood("G6", 0.1)).add(boing(700, 1100, 0.12, 0.05) * 0.3).out()


@sfx("ladder_climb", "board", "Snakes & ladders: climbing up the ladder", 0.75)
def _():
    m = Mix()
    for i, nt in enumerate(["C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"]):
        m.add(wood(hz(nt), 0.1), i * 0.08, 0.6).add(marimba(nt, 0.3), i * 0.08, 0.6)
    m.add(bell("C7", 0.9, tau=0.3, ratio=1.41), 0.66, 0.5)
    return reverb(m.out(), 0.12)


@sfx("snake_slide", "board", "Snakes & ladders: sliiide down the snake", 0.7)
def _():
    d = 1.1
    hiss = svf(noise(d), 6000, q=1, mode="hp") * hump(d) * 0.12
    m = Mix().add(slide_whistle("C6", "C4", d, vib=0.03)).add(hiss).add(thud(90, 0.25), d, 0.6)
    return m.out()


@sfx("piece_out", "board", "Ludo: piece leaves home base (plop)", 0.6)
def _():
    return Mix().add(pop(450, 0.12)).add(marimba("G5", 0.3), 0.03, 0.4).out()


@sfx("piece_capture", "board", "Ludo: piece knocked back home (bonk + zoom)", 0.7)
def _():
    m = Mix().add(wood("A4", 0.2)).add(boing(500, 250, 0.25) * 0.6).add(whoosh(0.4, 3500, 400, gain=0.6), 0.12)
    m.add(slide_whistle("G6", "C5", 0.4) * 0.35, 0.12)
    return m.out()


@sfx("piece_home", "board", "Piece reaches the finish", 0.8)
def _():
    m = Mix()
    arp(["G5", "C6", "E6"], 0.07, chime, 0.9, 0.7, mix=m)
    m.add(sparkle(0.5, 6, start=0.2))
    return reverb(m.out(), 0.18)


# ================================================================ fishing

@sfx("fish_cast", "fishing", "Cast the line: whoosh + reel spin", 0.6)
def _():
    m = Mix().add(whoosh(0.4, 600, 3500, q=2))
    m.add(svf(impulses(0.4, 60, 20), 3500, q=4, mode="bp") * 2.5 * perc(0.4, 0.01, 0.2), 0.1)
    return m.out()


@sfx("fish_splash_1", "fishing", "Hook hits the water", 0.6)
def _():
    m = Mix().add(water(0.4)).add(bubble(380, 0.09), 0.01).add(bubble(520, 0.07), 0.08, 0.5)
    return m.out()


@sfx("fish_splash_2", "fishing", "Bigger splash", 0.65)
def _():
    m = Mix().add(water(0.6, 3500))
    for i in range(4):
        m.add(bubble(rng.uniform(300, 700), 0.08), 0.03 + i * 0.07, 0.6)
    return m.out()


@sfx("fish_bubbles", "fishing", "Underwater bubbles (ambience)", 0.45)
def _():
    m = Mix()
    for _ in range(14):
        m.add(bubble(rng.uniform(350, 900), rng.uniform(0.05, 0.09)), rng.uniform(0, 1.4), rng.uniform(0.3, 1.0))
    return m.out()


@sfx("fish_reel", "fishing", "Reeling in: ratchet clicks", 0.55)
def _():
    d = 1.0
    return svf(impulses(d, 18, 26), 3200, q=5, mode="bp") * 3 * ahr(d, 0.02, 0.1)


@sfx("fish_bite", "fishing", "A fish bites! bobber tug", 0.6)
def _():
    return Mix().add(bubble(300, 0.1)).add(boing(260, 180, 0.25, 0.25) * 0.6, 0.03).add(bubble(420, 0.08), 0.12, 0.6).out()


@sfx("fish_catch", "fishing", "Fish caught! splash out + pop + ding", 0.8)
def _():
    m = Mix().add(water(0.35, 4000)).add(slide_whistle("G5", "C7", 0.25) * 0.4, 0.05).add(pop(800, 0.1), 0.3)
    arp(["E6", "G6", "C7"], 0.06, chime, 0.8, 0.5, start=0.32, mix=m)
    return reverb(m.out(), 0.15)


@sfx("fish_escape", "fishing", "Fish got away: splash + 'blub' down", 0.6)
def _():
    m = Mix().add(water(0.4)).add(slide_whistle("G5", "C5", 0.35) * 0.4, 0.1)
    m.add(bubble(500, 0.08), 0.4, 0.6).add(bubble(350, 0.1), 0.5, 0.6)
    return m.out()


# ================================================================ balloons

@sfx("balloon_inflate", "balloons", "Balloon blows up (squeaky rise)", 0.5)
def _():
    d = 0.7
    air = svf(noise(d), sweep(400, 1500, d), q=2, mode="bp") * 0.5
    squeak = osc(sweep(250, 700, d), d, "saw", vib=0.04, vib_rate=11) * 0.08
    return (air + squeak) * ahr(d, 0.05, 0.05)


def _balloon_pop(f):
    d = 0.25
    crack = svf(noise(d), 1800, q=0.7, mode="hp") * perc(d, 0.0005, 0.02)
    body = svf(noise(d), 700, mode="lp") * perc(d, 0.001, 0.05)
    return Mix().add(crack * 1.4).add(body).add(pop(f, 0.1), 0, 0.5).out()


@sfx("balloon_pop_1", "balloons", "Balloon pop (variant 1)", 0.7)
def _():
    return _balloon_pop(600)


@sfx("balloon_pop_2", "balloons", "Balloon pop (variant 2)", 0.7)
def _():
    return _balloon_pop(800)


@sfx("balloon_pop_3", "balloons", "Balloon pop (variant 3)", 0.7)
def _():
    return _balloon_pop(450)


@sfx("balloon_float", "balloons", "Balloon floats away", 0.45)
def _():
    return slide_whistle("C5", "C6", 0.9, vib=0.02, curve="lin") * 0.6


# ================================================================ hit the word (whack)

@sfx("whack_popup", "whack", "Word pops up from a hole", 0.5)
def _():
    return slide_whistle("C5", "G6", 0.13) * 0.6


@sfx("whack_hit", "whack", "Squeaky hammer bonk!", 0.75)
def _():
    m = Mix().add(osc(sweep(1500, 900, 0.12), 0.12, "saw") * ahr(0.12, 0.003, 0.05) * 0.2)  # squeak
    m.add(wood("D5", 0.2)).add(thud(110, 0.2), 0, 0.7)
    return m.out()


@sfx("whack_miss", "whack", "Hammer misses: swish", 0.5)
def _():
    return whoosh(0.2, 800, 2500, q=1.2)


# ================================================================ word train

@sfx("train_whistle", "train", "Choo-choo whistle", 0.65)
def _():
    d = 0.9
    m = Mix()
    for nt in ["A5", "C#6", "E6"]:
        f = hz(nt) * np.concatenate([np.linspace(0.94, 1, 2000), np.ones(int(SR * d) - 2000)])
        m.add(osc(f, d) * ahr(d, 0.05, 0.2), 0, 0.3)
    m.add(svf(noise(d), 2500, q=1, mode="bp") * ahr(d, 0.05, 0.2) * 0.25)
    return m.out()


@sfx("train_chug", "train", "Train chugs off (speeding up)", 0.6)
def _():
    m = Mix()
    at, gap = 0.0, 0.22
    for i in range(12):
        m.add(svf(noise(0.15), 900, q=1.2, mode="bp") * perc(0.15, 0.003, 0.05) * 2, at, 0.6 if i % 2 else 1.0)
        at += gap
        gap = max(0.09, gap * 0.9)
    return m.out()


@sfx("wagon_connect", "train", "Wagon clicks onto the train", 0.65)
def _():
    return Mix().add(glass(1700, 0.3) * 0.5).add(clack(2600, 0.08)).add(clack(2000, 0.08), 0.08, 0.6).out()


# ================================================================ frog jump

@sfx("frog_jump", "frog", "Frog jumps: boing", 0.6)
def _():
    return boing(220, 600, 0.35, 0.22)


@sfx("frog_croak", "frog", "Ribbit!", 0.6)
def _():
    m = Mix()
    for at, f, d in [(0, 170, 0.12), (0.16, 210, 0.1)]:
        pulses = (np.sin(2 * np.pi * 28 * tt(d)) > 0.2).astype(float)
        x = svf(osc(f, d, "saw") * pulses, 700, q=3, mode="bp") * ahr(d, 0.01, 0.03) * 3
        m.add(x, at)
    return m.out()


@sfx("frog_plop", "frog", "Frog lands in water", 0.6)
def _():
    return Mix().add(bubble(260, 0.12)).add(water(0.3), 0.01, 0.6).out()


@sfx("lily_land", "frog", "Frog lands on a lily pad", 0.55)
def _():
    return Mix().add(thud(140, 0.15)).add(wood("A5", 0.08), 0, 0.3).add(bubble(600, 0.06), 0.03, 0.4).out()


# ================================================================ memory cards

@sfx("card_flip", "memory", "Card flips", 0.5)
def _():
    d = 0.12
    return svf(noise(d), sweep(1500, 5000, d), q=1.2, mode="bp") * perc(d, 0.003, 0.03) * 1.8


@sfx("card_match", "memory", "Pair found! two-bell harmony", 0.75)
def _():
    m = Mix().add(chime("E6", 0.8)).add(chime("G6", 0.8), 0.1).add(chime("C7", 1.0), 0.2)
    return reverb(m.out(), 0.18)


@sfx("card_mismatch", "memory", "Not a pair: soft double boop", 0.5)
def _():
    return Mix().add(tone("D5", 0.1, "sine", 0.005, 0.05)).add(tone("A4", 0.18, "sine", 0.005, 0.1), 0.13).out()


# ================================================================ treasure

@sfx("treasure_dig", "treasure", "Shovel digs in sand", 0.6)
def _():
    m = Mix()
    for i in range(3):
        d = 0.18
        m.add(svf(noise(d), 1800, q=0.8, mode="bp") * perc(d, 0.01, 0.06) * 1.5, i * 0.25)
        m.add(thud(120, 0.1), i * 0.25, 0.3)
    return m.out()


@sfx("chest_open", "treasure", "Treasure chest creaks open + shine", 0.8)
def _():
    d = 0.6
    creak = svf(impulses(d, 35, 90, jitter=0.2), sweep(600, 1100, d), q=4, mode="bp") * 3 * ahr(d, 0.05, 0.1)
    m = Mix().add(creak)
    m.add(chord(["C6", "E6", "G6", "B6"], lambda f, dd: bell(f, dd, tau=0.6, ratio=1.41), 1.6), 0.55, 0.7)
    m.add(sparkle(1.0, 14, start=0.55))
    return reverb(m.out(), 0.22, tau=0.35)


@sfx("coins_shower", "treasure", "Coins pour out", 0.65)
def _():
    m = Mix()
    for i in range(16):
        m.add(glass(rng.uniform(2200, 3600), 0.25, 0.08), i * 0.045 + rng.uniform(0, 0.03), rng.uniform(0.3, 0.8))
    return m.out()


# ================================================================ letter writing

@sfx("chalk_stroke", "writing", "Pencil/chalk drawing (loop while tracing)", 0.4)
def _():
    d = 0.8
    strokes = np.abs(svf(noise(d), 12, mode="lp")) * 30
    x = svf(noise(d), 3000, q=1.2, mode="bp") * np.clip(strokes, 0, 1)
    return x * ahr(d, 0.02, 0.02)


@sfx("stroke_done", "writing", "One stroke traced correctly", 0.55)
def _():
    return chime("A6", 0.4)


@sfx("letter_traced", "writing", "Whole letter written! sparkle chord", 0.8)
def _():
    m = Mix()
    arp(["C6", "E6", "G6", "C7"], 0.05, chime, 1.0, 0.7, mix=m)
    m.add(sparkle(0.6, 8, start=0.15))
    return reverb(m.out(), 0.2)


@sfx("stroke_off", "writing", "Finger went off the path: soft tick", 0.45)
def _():
    return tone("E4", 0.12, "tri", 0.005, 0.06)


@sfx("sponge_wipe", "writing", "Sponge wipes the chalkboard: three soft swishes", 0.55)
def _():
    m = Mix()
    for i, (lo, hi) in enumerate([(700, 2200), (900, 2600), (650, 2000)]):
        m.add(whoosh(0.4, lo, hi, gain=0.7), i * 0.42)
    return m.out()


# ================================================================ word race

@sfx("race_zoom", "race", "Racer zooms past", 0.6)
def _():
    d = 0.5
    f = sweep(500, 260, d, "lin")
    eng = svf(osc(f, d, "saw"), 1500, mode="lp") * hump(d) * 0.5
    return Mix().add(eng).add(whoosh(d, 800, 2500, gain=0.5)).out()


@sfx("race_boost", "race", "Speed boost", 0.65)
def _():
    return Mix().add(slide_whistle("C5", "C7", 0.3) * 0.5).add(whoosh(0.35, 500, 5000, gain=0.6)).add(sparkle(0.3, 4), 0.2).out()


@sfx("race_finish", "race", "Crossing the finish line", 0.85)
def _():
    m = Mix().add(bell("G6", 1.0, tau=0.3)).add(bell("G6", 1.0, tau=0.3), 0.16).add(bell("C7", 1.3, tau=0.5), 0.32)
    m.add(osc(sweep(320, 560, 0.5), 0.5, "saw") * ahr(0.5, 0.02, 0.1) * 0.15, 0.3)
    return reverb(m.out(), 0.18)


# ================================================================ tug of war

@sfx("rope_pull", "tug", "Rope stretches (creak)", 0.55)
def _():
    d = 0.5
    return svf(impulses(d, 60, 110, jitter=0.3), 700, q=3, mode="bp") * 3 * hump(d)


@sfx("rope_win", "tug", "Team falls over: whoosh + thump + jingle", 0.8)
def _():
    m = Mix().add(whoosh(0.3, 600, 2500)).add(thud(80, 0.3), 0.25)
    arp(["C6", "E6", "G6"], 0.07, marimba, 0.6, 0.8, start=0.4, mix=m)
    return m.out()


# ================================================================ ice tower

@sfx("ice_place", "ice_tower", "Ice block placed: glassy clink", 0.6)
def _():
    return Mix().add(glass(rng.uniform(1800, 2400), 0.5)).add(thud(200, 0.1), 0, 0.3).out()


@sfx("ice_crack", "ice_tower", "Ice cracks", 0.65)
def _():
    d = 0.5
    cr = svf(impulses(d, 120, 30, jitter=0.6), 3500, q=1.5, mode="bp") * 3 * perc(d, 0.002, 0.2)
    return Mix().add(cr).add(glass(2900, 0.3), 0, 0.4).out()


@sfx("ice_tumble", "ice_tower", "Tower tumbles down", 0.75)
def _():
    m = Mix()
    for i in range(12):
        m.add(glass(rng.uniform(1300, 3000), 0.4, 0.12), i * 0.07 + rng.uniform(0, 0.04), rng.uniform(0.3, 0.8))
    m.add(thud(70, 0.4), 0.85)
    return m.out()


# ================================================================ shop order

@sfx("shop_item", "shop", "Item drops into the basket", 0.55)
def _():
    return Mix().add(pop(380, 0.12)).add(wood("C5", 0.12), 0.02, 0.4).out()


@sfx("shop_scan", "shop", "Checkout beep", 0.5)
def _():
    return tone(1800, 0.12, "sine", 0.003, 0.03)


@sfx("cash_register", "shop", "Cha-ching!", 0.75)
def _():
    m = Mix().add(clack(1500, 0.08)).add(clack(1200, 0.08), 0.07)
    m.add(bell("E7", 1.0, tau=0.4, ratio=2.2, index=1.5), 0.15).add(glass(3200, 0.6), 0.15, 0.4)
    return m.out()


# ================================================================ match end

@sfx("game_win", "game_end", "You won the game! (short jingle)", 0.85)
def _():
    m = Mix()
    for nt, at in [("G5", 0), ("C6", 0.1), ("E6", 0.2), ("G6", 0.3), ("E6", 0.45), ("G6", 0.55)]:
        m.add(marimba(nt, 0.6), at).add(pluck(nt, 0.6, 0.6), at, 0.4)
    m.add(doum(), 0.55).add(chord(["C6", "E6", "G6"], chime, 1.2), 0.55, 0.6)
    m.add(sparkle(0.9, 12, start=0.55))
    return reverb(m.out(), 0.18)


@sfx("game_lose", "game_end", "Nono/Fofo won this time: friendly 'aww' + rise", 0.65)
def _():
    m = Mix().add(brass("E4", 0.3)).add(brass("D#4", 0.6, vib=0.03), 0.3)
    arp(["C5", "G5"], 0.12, chime, 0.9, 0.4, start=1.0, mix=m)
    return reverb(m.out(), 0.12)


@sfx("game_draw", "game_end", "It's a draw: two equal chimes", 0.6)
def _():
    return reverb(Mix().add(chime("E5", 0.7)).add(chime("E5", 0.9), 0.2).add(chime("C6", 0.9), 0.2, 0.6).out(), 0.15)


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
        entries[sid] = {"file": f"sfx/{sid}.wav", "group": s["group"], "desc": s["desc"], "duration": round(dur, 2)}

    manifest = {}
    if os.path.exists(MANIFEST):
        with open(MANIFEST) as f:
            manifest = json.load(f)
    manifest["version"] = 1
    manifest["sfx"] = entries
    with open(MANIFEST, "w") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"{len(entries)} sounds -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main(set(sys.argv[1:]))
