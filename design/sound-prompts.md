# Nono & Fofo: music & voice prompts

The short sound effects (correct, wrong, stars, dice, Connect 4, fishing, …) are
already made in code: `assets/audio/sfx/`. Listen to them on the sound board
(`design/sound-board.html`).

This file is for the two things code can't do well:

1. **Background music**: one track per map place plus game loops (Suno or ElevenLabs Music)
2. **The brothers' cartoon voices**: giggles, woohoo, uh-oh… (ElevenLabs Sound Effects, or record real kids)

## Where to put the files

Drop what you generate here (any of mp3 / wav / m4a, using exactly these names):

```
Sounds/music/<id>.mp3            e.g. Sounds/music/place_nile.mp3
Sounds/voice/nono/<id>.mp3       e.g. Sounds/voice/nono/woohoo.mp3
Sounds/voice/fofo/<id>.mp3
```

Then run:

```bash
tools/.venv/bin/python tools/audio/process_audio.py
```

It trims silence, levels the volume, makes music loop seamlessly, converts to
`.m4a`, and updates `assets/audio/manifest.json`. The sound board shows what is
still missing.

---

## 1. Background music (Suno / ElevenLabs Music)

**Settings for every track:**
- **Instrumental ON** (no vocals at all)
- Length: about **1:30 to 2:00**
- Generate 2–4 versions and keep the best one
- If one comes out with singing or a fade-out ending, regenerate it

**Paste this line at the end of every style prompt** (it keeps the tracks one family):

```
children's game soundtrack, instrumental, no vocals, cheerful and warm, clean mix, steady tempo, loopable, ends on the downbeat without fade-out
```

### map_theme: the Egypt map / home screen
The main theme. Everything else is a variation of this mood.
```
Playful Egyptian adventure theme for kids, bouncy qanun and pizzicato strings melody, light darbuka and riq groove, hand claps, warm oud chords, sunny and curious, a hummable main melody, maqam ajam (major) feeling, 110 BPM
```

### place_grandpa_house: Grandpa's house (the story starts here)
```
Cozy warm kids' music, gentle oud and soft piano, light brushed percussion, ticking clock feel, homely and safe, a little mysterious like opening an old storybook, 85 BPM
```

### place_nile: the Nile & the felucca
```
Flowing peaceful kids' music, nay flute melody over gentle qanun arpeggios, soft water-like harp, light riq shimmer, calm boat ride on a sunny river, 90 BPM, 6/8 swaying feel
```

### place_village: the Egyptian village
```
Happy Egyptian folk kids' music, mizmar or bright reed melody, lively darbuka saidi rhythm, tabla baladi, hand claps, playful and bouncy, village festival with friends, 115 BPM
```

### place_pyramids: the Pyramids
```
Adventurous kids' treasure-hunt music, pizzicato strings and marimba, low frame drum, darbuka, short heroic brass hits, mysterious but fun, not scary, exploring the pyramids, maqam hijaz flavor, 105 BPM
```

### place_monastery: the desert monastery
```
Calm peaceful kids' music, soft bells and gentle chimes, warm pad, slow oud melody, light desert wind, serene and safe, wonder and quiet joy, 75 BPM
```
(Keep it instrumental and non-liturgical. It's background, not a hymn.)

### place_alexandria: Alexandria & the sea
```
Breezy seaside kids' music, ukulele and qanun melody, glockenspiel, light shaker and darbuka, soft ocean feel, seagulls mood, happy summer day by the Mediterranean, 112 BPM
```

### game_loop_1: board games (Ludo, Snakes & Ladders, Connect 4)
```
Upbeat playful game-board music for kids, marimba and xylophone melody, plucky bass, light drums and claps, cheeky and fun, friendly competition, 120 BPM
```

### game_loop_2: catch & tap games (fishing, balloons, hit the word, frog)
```
Bouncy cartoon game music for kids, ukulele, toy piano and glockenspiel, whistles, light funky drums, silly and energetic, 125 BPM
```

### game_race: timed games (word race, tug of war, word train)
```
Fast exciting kids' race music, driving darbuka and drums, pizzicato strings, bright brass stabs, playful urgency but not stressful, 140 BPM
```

---

## 2. The brothers' voices

Rule from the spec: **cartoon sounds only, no words or sentences.**
Exclamations like "woohoo", "yay", "uh-oh", "hmm" are fine.

### Option A: record real kids (recommended if possible)
Two kids with similar ages (9 and 6) reacting naturally on a phone in a quiet
room (closet full of clothes = great studio). 3–4 takes of each sound below,
about 30 cm from the phone. This sounds the most alive by far.

### Option B: ElevenLabs Sound Effects
Settings: duration **Auto** (or 1–2 s), prompt influence **high**. Generate 4
takes per sound and keep the best. Start every prompt with the character line:

- **Nono:** `Cartoon voice of an energetic 9-year-old boy, excited and fast, `
- **Fofo:** `Cartoon voice of a sweet calm 6-year-old boy, gentle and curious, `

…and end every prompt with:
`single short vocalization, no other words, clean dry studio recording, no music, no background noise`

| id | Nono (rushes) | Fofo (thinks) | Used when |
|---|---|---|---|
| `yay` | shouting a big happy "yaaay!" | a happy little "yay!" | correct answer |
| `woohoo` | shouting "woo-hoo!" while jumping | (skip) | level complete / celebrate |
| `giggle` | quick cheeky giggle | soft shy giggle | wave, idle tap |
| `laugh` | big belly laugh | happy laugh | win the game |
| `wow` | amazed "woooow!" | quiet amazed "wow…" | star 3, new place |
| `uh_oh` | "uh-oh!" quick and embarrassed | "uh-oh" | wrong answer |
| `aww` | disappointed "awww" | soft "aww" | level not passed, lose game |
| `gasp` | surprised gasp | surprised gasp | surprised pose |
| `hmm` | (skip) | thinking "hmmm…" | hint, Fofo thinking |
| `aha` | (skip) | "a-ha!" got an idea | hint revealed |
| `huh` | confused "huh?" | (skip) | wrong answer, Nono |
| `pant` | out of breath panting after running | (skip) | run |
| `yawn` | big yawn | small yawn | sleep pose |
| `snore` | cute cartoon snore | tiny soft snore | sleep pose (idle too long) |

Save as `Sounds/voice/nono/yay.mp3`, `Sounds/voice/fofo/hmm.mp3`, etc.

---

## Tips
- Kids hear the correct/wrong sounds hundreds of times, so the app rotates
  variants (`correct_1..3`, `wrong_1..2`) and mixes in a voice now and then
  (not every time).
- Music volume in the app should sit well under the effects: about 35% for
  music and 100% for effects. The parent corner gets separate music and
  sound switches.
