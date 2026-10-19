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
| `tools/synth_intro.py` | Logo intro: cuts the logo into blocks (`remotion/src/intro/layout.json`) and composes its score |
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
tools/.venv/bin/python social/tools/synth_intro.py        # (from repo root) rebuild intro layout + score
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
| `intro_logo_blocks` | 25.5 s score, 120 BPM, D hijaz: darbuka maqsum, bass, qanun plucks, block landings as a marimba melody, risers, final sting. Made by `tools/synth_intro.py`, cued from `remotion/src/intro/cues.json` | Logo intro |

All 107 app SFX (`correct_1`, `confetti`, `fish_splash_1`, …) can be used by id
too; see `app/assets/audio/manifest.json`.

### Images (`assets/images/`)

None yet.

### Icons (keyword cards)

Font Awesome, registered in `remotion/src/icons.ts`: `book`, `clap`, `fish`,
`football`, `heart`, `house`, `idea`, `paint`, `puzzle`, `question`, `rocket`,
`run`, `star`, `trophy`.

## Logo intro

A 25.5 s motion-graphics intro built only from the app logo, in two shapes:
`intro-landscape` (1920×1080) and `intro-portrait` (1080×1920), 60 fps. Code in
`remotion/src/intro/`. Picture and sound share one clock, `cues.json`: change a
time there, rerun `synth_intro.py`, and re-render.

1. **Close-ups (0–5 s):** tiny parts of the logo, rebuilt as sharp vectors
   (a gold Coptic letter, the pyramid, a palm, the Nile, the book's letters),
   cut on each beat.
2. **Pull-back (5–6 s):** each close-up turns out to be the face of a floating
   alphabet block. The blocks shoot away into the dark, then a hit.
3. **Blocks (6–16 s):** the logo, cut into 60 wooden Coptic-letter blocks, drops
   onto a board row by row (each landing is a marimba note). The camera swings to
   the front, a wave flips every block to show the picture, Nono's and Fofo's faces
   pop out, then the light cracks through.
4. **Alive (16–22 s):** a dive into the book (letters rise out), a whip to the
   pyramid (pyramid, palms and sun fold up like a pop-up book), then down the
   Nile and out. The ring draws itself and a shine sweeps across.
5. **Sting (22–25.5 s):** shockwave, a burst of letters and confetti, the logo holds.

## Videos

| Folder | Title | Status |
|---|---|---|
| `001-nono-hello` | Nono says hi (demo) | Voiced (one take split into 4 lines) · rendered |
| `002-fofo-hello` | Fofo says hi (demo) | Voiced (one take split by hand with `--lines`) · rendered |

<p>
  <img src="previews/001-nono-hello.jpg" width="240" alt="Nono demo: run keyword card">
  <img src="previews/002-fofo-hello.jpg" width="240" alt="Fofo demo: puzzles and drawing keyword cards">
</p>
