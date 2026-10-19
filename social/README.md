# Nono & Fofo · Social media (TikTok & Instagram)

Portrait motion-graphics videos (1080×1920, 30 fps) for kids 7–9: Egyptian
Arabic voices, Arabic + English captions, keyword pop-ups, scenes of 4–5 s max.
Motion is built in code with [Remotion](https://www.remotion.dev); voices come
from ElevenLabs (Eleven v3). The workflow lives in the `social-media` skill
(`.claude/skills/social-media/SKILL.md`).

## Folder map

| Path | What |
|---|---|
| `videos/<NNN-slug>/script.md` | The ElevenLabs script: line files, v3 text with emotion tags, captions |
| `videos/<NNN-slug>/video.json` | The scene list Remotion renders (format: `remotion/src/types.ts`) |
| `videos/<NNN-slug>/voice/` | The voice MP3s from ElevenLabs, named after each line id |
| `voices.md` | Nono's and Fofo's ElevenLabs voice prompts + v3 writing rules |
| `assets/` | **Social-only** resources (catalogued below and in `assets/manifest.json`) |
| `tools/split_voice.py` | Splits one ElevenLabs take into the per-line voice files |
| `tools/synth_social_sfx.py` | Synthesizes the social sound effects into `assets/sfx/` |
| `tools/synth_intro.py` | Composes the logo intro's score from `remotion/src/intro/cues.json` |
| `remotion/` | The Remotion project (components, timing, render scripts) |
| `previews/` | One still per video for the README and PRs |
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
npm run intro                           # logo intro -> out/intro-landscape.mp4 + out/intro-portrait.mp4
npm run still -- intro-portrait 12.5    # one intro frame
tools/.venv/bin/python social/tools/synth_intro.py        # (from repo root) rebuild the intro score
tools/.venv/bin/python social/tools/synth_social_sfx.py   # (from repo root) rebuild social SFX
```

## Asset catalog (social-only)

### Sound effects (`assets/sfx/`, made by `tools/synth_social_sfx.py`)

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

### Music (`assets/music/`)

| id | Track | Used for |
|---|---|---|
| `intro_logo_book` | 25 s score, 120 BPM, D hijaz: Grandpa's clock, lamp click, qanun motif, creaking cover, a paper pop per pop-up, Nile water, desert wind, pigeons, page turns, the alphabet rising, final drop. Made by `tools/synth_intro.py`, cued from `remotion/src/intro/cues.json` | Logo intro |

All 107 app SFX (`correct_1`, `confetti`, `fish_splash_1`, …) can be used by id
too; see `app/assets/audio/manifest.json`.

### Images (`assets/images/`)

None yet.

### Icons (keyword cards)

Font Awesome, registered in `remotion/src/icons.ts`: `book`, `clap`, `fish`,
`football`, `heart`, `house`, `idea`, `paint`, `puzzle`, `question`, `rocket`,
`run`, `star`, `trophy`.

## Logo intro ("Grandpa's Pop-up Book")

A 25 s intro built in CSS 3D, in two shapes: `intro-portrait` (1080×1920) and
`intro-landscape` (1920×1080), 60 fps. Code in `remotion/src/intro/`
(`Book.tsx` is the 3D rig, `PaperArt.tsx` the printed pages and pop-up pieces).
Picture and sound share one clock, `cues.json`, which also lists every pop-up
piece (kind, place, height, when it folds up). Change it, rerun
`synth_intro.py`, and re-render.

1. **The study (0–2.5 s):** Grandpa's clock ticks, a lamp clicks on over his
   closed book (gold ⲁ ⲱ on the cover).
2. **The cover opens (2.5–3.5 s).**
3. **The Nile:** palms and papyrus fold up, a felucca sails across.
4. **The pyramids:** three pyramids, palms, the sun rises on a pull-tab.
5. **The village:** houses, a pigeon tower, then Nono and Fofo pop up and wave.
6. **The alphabet:** the letters lift off the last page in gold and circle up.
7. **The logo (19–25 s):** the logo card folds up and floats inside the ring,
   the camera drops to eye level, and on the hit the logo holds, perfectly still.

## Videos

| Folder | Title | Status |
|---|---|---|
| `001-nono-hello` | Nono says hi (demo) | Voiced (one take split into 4 lines) · rendered |
| `002-fofo-hello` | Fofo says hi (demo) | Voiced (one take split by hand with `--lines`) · rendered |

<p>
  <img src="previews/001-nono-hello.jpg" width="240" alt="Nono demo: run keyword card">
  <img src="previews/002-fofo-hello.jpg" width="240" alt="Fofo demo: puzzles and drawing keyword cards">
</p>
