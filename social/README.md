# Nono & Fofo · Social media (TikTok & Instagram)

Portrait motion-graphics videos (1080×1920, 30 fps) for kids 7–9: Egyptian
Arabic voices, Arabic + English captions, keyword pop-ups, scenes of 4–5 s max.
Motion is built in code with [Remotion](https://www.remotion.dev); voices come
from ElevenLabs (Eleven v3). The workflow lives in the `social-media` skill
(`.claude/skills/social-media/SKILL.md`).

## Folder map

| Path | What |
|---|---|
| `videos/<NNN-slug>/script.md` | *(local only)* The ElevenLabs script: line files, v3 text with emotion tags, captions |
| `videos/<NNN-slug>/video.json` | The scene list Remotion renders (format: `remotion/src/types.ts`) |
| `videos/<NNN-slug>/voice/` | The voice MP3s from ElevenLabs, named after each line id |
| `voices.md` | Nono's and Fofo's ElevenLabs voice prompts + v3 writing rules |
| `assets/` | **Social-only** resources (catalogued below and in `assets/manifest.json`) |
| `tools/split_voice.py` | Splits one ElevenLabs take into the per-line voice files |
| `tools/synth_social_sfx.py` | Synthesizes the social sound effects into `assets/sfx/` |
| `tools/synth_intro.py` | *(local only)* Logo intro: cuts the logo into blocks and composes its score |
| `tools/stitch_intro.py` | *(local only)* Stitch intro: logo line-art frames and its score |
| `tools/spin_intro.py` | *(local only)* Paper-cut spin intro: composes its score |
| `remotion/` | The Remotion project (components, timing, render scripts) |
| `previews/` | *(local only)* One still per video |
| `out/` | Rendered MP4s and stills (git-ignored) |

## Where resources come from

- **From the app (never copied by hand, never edited here):** characters
  (`app/assets/characters`), colors (`AppColors` in `app_colors.dart`), fonts
  (Baloo Bhaijaan 2, Baloo 2, Avva Shenouda), music, SFX and the logo.
  `npm run sync` copies them into `remotion/public/` and reads the colors, so
  anything new added to the app is available to the videos automatically.
- **Social-only:** anything the videos need that the app doesn't goes in
  `assets/` and gets a row in the catalog below **and** an entry in
  `assets/manifest.json`.

## Commands

Run inside `social/remotion` (first time: `npm install`).

```bash
npm run studio                          # live preview / scrub in the browser
npm run still -- 001-nono-hello 2.5     # one frame -> out/001-nono-hello@2.5s.jpg
npm run render -- 001-nono-hello        # full video -> out/001-nono-hello.mp4
npm run release -- 001-nono-hello 6.5   # finished post -> out/release/001-nono-hello/ (HQ video.mp4 + thumbnail.jpg)
npm run intro                           # logo intro -> out/intro-landscape.mp4 + out/intro-portrait.mp4
npm run still -- intro-portrait 12.5    # one intro frame
tools/.venv/bin/python social/tools/synth_intro.py        # (from repo root) rebuild intro layout + score
tools/.venv/bin/python social/tools/stitch_intro.py       # (from repo root) rebuild the stitch intro art + score (--music: score only)
npm run still -- intro-stitch 3.2       # one frame of the stitch intro
npm run render -- intro-spin            # paper-cut spin intro -> out/intro-spin.mp4
tools/.venv/bin/python social/tools/synth_social_sfx.py   # (from repo root) rebuild social SFX
```

## Asset catalog (social-only)

### Sound effects (`assets/sfx/`, made by `tools/synth_social_sfx.py`; *ElevenLabs* ones are generated, prompts in their video's `sounds.md`)

| id | Sound | Used for |
|---|---|---|
| `mg_whoosh_in` | Airy whoosh up | Character flies in (automatic) |
| `mg_whoosh_out` | Whoosh down | Something flies out |
| `mg_scene_swipe` | Swish + tick | Scene wipe (automatic) |
| `mg_keyword_pop` | Pop + ding | Keyword card (automatic, 1st/3rd…) |
| `mg_keyword_pop_2` | Pop + chime | Keyword card (automatic, 2nd/4th…) |
| `mg_word_tick` | Tiny tick | Caption word highlight (optional) |
| `mg_boing` | Cartoon boing | Bounce / "pop" entrance (automatic) |
| `mg_pose_swap` | Quick "fwip" | Pose change (automatic) |
| `mg_slide_up` / `mg_slide_down` | Slide whistle | Rising / dropping things |
| `mg_logo_sting` | Darbuka + qanun run + sparkles | End card (automatic) |
| `mg_sparkle` | Magic shimmer | Stars, shining letters |
| `mg_ta_da` | Marimba + bell reveal | Big moment / catchphrase |
| `mg_boom` | Big soft thump + papery crash + shimmer | Crash / BOOM (Nono into the book) |
| `mg_skid` | Squeaky sneaker slide | Character skids to a stop |
| `mg_pant` | Breathy hah-huh panting | A character out of breath |
| `mg_stone_wake` | Stone grinding + crumbling + shimmer *(ElevenLabs)* | Statues come alive |
| `mg_stone_eyes` | Gritty stone scrape + squeak *(ElevenLabs)* | A statue's eyes slide sideways |
| `mg_stone_tiptoe` | Little stone feet tiptoeing on marble *(ElevenLabs)* | Small statues sneaking around |
| `mg_stone_run` | Clattering stone footsteps + whoosh *(ElevenLabs)* | Statues running past |

### Music (`assets/music/`)

| id | Track | Used for |
|---|---|---|
| `intro_logo_blocks` | 25.5 s score, 120 BPM, D hijaz: darbuka maqsum, bass, qanun plucks, block landings as a marimba melody, risers, final sting. Made by `tools/synth_intro.py`, cued from `remotion/src/intro/cues.json` | Logo intro |
| `intro_stitch` | 4.5 s score, 120 BPM, D hijaz: needle whoosh, spinning whirr and qanun run, a zip per stitch, marimba while the lines draw, swell into the knot (boom, bell chord, darbuka), fly-out whoosh. Made by `tools/stitch_intro.py`, cued from `remotion/src/intro/stitch.json` | Stitch intro |
| `intro_spin` | 5 s score, 120 BPM, D hijaz: knife slices, paper pop, spinning whirr with darbuka and qanun, slide whistle, three ring landings, logo rise hit with bell chord, typing taps. Made by `tools/spin_intro.py`, cued from `remotion/src/intro/spin.json` | Paper-cut spin intro |

All 107 app SFX (`correct_1`, `confetti`, `fish_splash_1`, …) can be used by id
too; see `app/assets/audio/manifest.json`.

### Characters (guests, `assets/images/`, registered under `characters` in the manifest)

| who | Poses | Used for |
|---|---|---|
| `ramses` | `idle`, `look`, `talk`, `demand`, `smile` (`ramses-<pose>.png`, cut-out) | Giant living statue of Ramses II (video 004), voice `Ramses` in `voices.md` |

Use them like the brothers (`"who": "ramses"` in `characters`, `"speaker": "ramses"`
on a line). A pose without its PNG yet is drawn as a sandstone placeholder.

### Images (`assets/images/`)

| id | Image | Used for |
|---|---|---|
| `statue-cat`, `statue-ushabti` | The two little living statues (cut-outs) | `statues` prop (drawn shapes stand in until the PNGs exist) |
| `gem-hall` | Grand Egyptian Museum hall, portrait, empty floor in the middle | `backdrop` of the museum scenes (a drawn hall stands in until the PNG exists) |

### Icons (keyword cards)

Font Awesome, registered in `remotion/src/icons.ts`: `anchor`, `arrowLeft`,
`arrowRight`, `bolt`, `book`, `cake`, `check`, `church`, `clap`, `compass`, `fish`,
`football`, `gift`, `heart`, `house`, `idea`, `map`, `medal`, `museum`, `paint`, `puzzle`,
`question`, `rocket`, `run`, `sailboat`, `search`, `shield`, `shoes`, `sound`,
`star`, `trophy`.

### Scene backgrounds (`pattern`, `remotion/src/components/Scenery.tsx`)

Besides `rays`, `dots` and `letters`, a scene can use a themed moving background:

| pattern | What |
|---|---|
| `cairo` | Cairo skyline: buildings, domes, minarets, Cairo Tower, far pyramids, drifting clouds, birds, twinkling windows |
| `field` | Football pitch with glowing gold lines that draw in, sparkles running along them |
| `doodles` | Crayon drawings that draw themselves (sun, house, star, heart…) + floating puzzle pieces |
| `icons` | Icons from `icons` (e.g. `["idea","star"]`) float up and light up one by one |
| `study` | Grandpa's study: mashrabiya window with light beams, bookshelf, rug, dust in the light |
| `waves` | Sea with moving waves and a felucca sailing by |
| `desert` | Sun, scrolling dunes and a swaying palm |
| `board` | Chalkboard with faint chalk letters being written and chalk dust |
| `grid` | Notebook grid paper with floating numbers |
| `track` | Running track with a cheering crowd and lane marks rushing by |
| `trail` | Footprints appearing one by one across the screen |

### Motion props (`remotion/src/components/Props.tsx`)

Story graphics a scene can add with `props` in `video.json` (times in seconds
from the voice start, like keywords; format in `remotion/src/types.ts`):

| kind | What |
|---|---|
| `book` | Grandpa's golden Coptic book: glows, opens (`openAt`), bursts its letters out (`burstAt`), one letter flies back in (`letterInAt`) |
| `egypt` | Simple Egypt map: the Nile draws in, story places pop up (Alexandria, Pyramids, monastery, village, Nile) and gold letters land all over it |
| `letter` | A big gold Coptic letter: floats down, turns into a pyramid and back (`pyramidAt` / `letterAt`), grows into the letter card (name ribbon + capital and small tiles, `cardAt`), "says" its sound with a sound chip such as "ا = a" (`pulseAt`, `sound`, `soundEn`), flies away (`outAt`) |
| `slots` | Letter counter: a row of empty slots with found letters in gold; can stretch to more slots (`to`, `stretchAt`) with a "فاضل ٩ / 9 left" label |
| `speed` | Speed lines (running) |
| `ball` | Football bounces in from the right and keeps hopping |
| `rain` | Gold Coptic letters rain down and bounce off the brothers' heads |
| `shake` | Screen shake (crash) |
| `arrow` | Bouncing "this way" arrow |
| `runner` | A Coptic letter on little legs with eyes, running along `path` keyframes (`hop` arcs it, e.g. bouncing off a head) |
| `statues` | Two little living statues (cat + ushabti images) tiptoeing and searching; `chaseAt` sends them running off, `passAt` runs them across the screen in a line |
| `dizzy` | Stars spinning around a head after a bonk |
| `pant` | Breath puffs + sweat drops (out of breath) |
| `compare` | A Coptic letter tile ≈ a Latin letter tile (Ⲉ ≈ E); stays put on screen while the camera moves, `outAt` hides it |
| `confetti` | Confetti burst |

`book` also takes `letter` (the Avva key that flies in), `found` (a letter already on the page) and `only` (show just those letters).
Keyword cards can show the word spelled in Coptic: `coptic` (Avva keys) on the keyword. `side` (`left` / `center` / `right`) moves a card off a face.

Characters can also take `size`, `x`, `delay` (late entrance), `moves`
(slide sideways, or down with `toY`: run across, run off, come back, with `flip`) and `jumps`
(hop up and down, e.g. reaching for something high). A pose swap with `fade` dissolves
into the new pose (no hop, no sound).

Scenes can also take:
- `camera`: keyframes (`at` in scene seconds, `x`/`y` offset, `zoom`, `rot`,
  `dur`). The brothers and props move with the camera, the background follows
  with parallax (Cairo skyline, track, icons, study, rays…), captions and
  keyword cards stay put. Use it to pan to a brother, follow a run, or punch in.
- `backdrop`: an image id from the catalog drawn behind the scene; it moves exactly with the camera (the characters stand on its floor).
- `transition`: `wipe` (circle, default), `whip` (fast blurred camera whip)
  or `cut` (same shot continues, no wipe or sound).
- `patternAt`: the themed background appears on a word (e.g. the pitch on "الكورة");
  `before` (`{pattern, icons}`) is what shows until then, so the scene is never plain.

A long line can show as several subtitles: `chunks` on the line (`from` = index of the
chunk's first Arabic word, `en` = its English).

The end card can have a voice: `endCard.voice` is a file id in the video's `voice/`
folder (e.g. both brothers saying the sign-off); the card stretches to fit it.

## Logo intro

Local only (not in git): `remotion/src/intro/` and `tools/synth_intro.py`. When
present, `npm run sync` registers its compositions (`intro-portrait`,
`intro-landscape`) through `src/generated/local.ts`; its score is the
`intro_logo_blocks` resource above.

**Stitch intro.** `intro-stitch`, 4.5 s, its own clip (not added to the videos):
a golden needle winds five spinning ribbons of thread into the logo's ring, sews
it, the line-art draws itself, the colour blooms in, the knot pulls tight with the
brothers' shout and a "نونو وفوفو / Nono & Fofo" patch, then the logo flies into the
corner where the videos' watermark sits, so a video placed after it carries on.
Render: `npm run render -- intro-stitch`. Timeline: `src/intro/stitch.json`; art +
score: `tools/stitch_intro.py`; files it uses (art frames, the shout voice in
`media/voice/shout.mp3`, script in `src/intro/shout.md`) live in `src/intro/media/`
and are copied to `public/intro/` by `npm run sync`.

**Paper-cut spin intro.** `intro-spin`, 5 s, its own clip: circles are cut into
deep-teal paper, the rings pop out and spin like a gyroscope over a dark hole, the
centre disc tumbles away to show the logo, the rings land flat, the cuts heal, and
the logo rises out of the paper while "نونو وفوفو / Nono & Fofo" types in. Plays the
same shout as the stitch intro when `media/voice/shout.mp3` exists. Timeline:
`src/intro/spin.json`; motion: `src/intro/Spin.tsx`; score: `tools/spin_intro.py`.

## Videos

Videos are local only: `videos/`, `previews/` and `out/` are git-ignored. Git holds
the resources (`assets/`), the Remotion engine, the tools and the skill.
