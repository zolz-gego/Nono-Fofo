---
name: whiteboard-letter
description: Make a whiteboard-animation reel (TikTok / Instagram, ~80–110 s) that teaches ONE Coptic letter in Egyptian Arabic — a marker (no hand) writes and draws on a white board in sync with a narration the user records from the tagged script Claude writes (Claude never generates audio); mostly about the letter itself (its name, rank, two forms, look, sound, vowel or not, number value, a church fact), then 1–2 Arabic words and 3–4 Coptic words with colour drawings, Coptic spellings and Arabic transliterations, a recap and a follow end card. Always built and rendered with HyperFrames, and released with a thumbnail, TikTok + Instagram captions and a story hook. Use whenever the user asks for a whiteboard / letter explainer video for a Coptic letter.
---

# Whiteboard letter videos

One Coptic letter per video, portrait 1080×1920, 30 fps, **Arabic only** (no
English words, no English narration, no Latin transliterations on the board).
**Always HyperFrames, never Remotion.** Everything lives in its own folder,
**`social/whiteboard/`** (map: `social/whiteboard/README.md`), reused for every letter:
- `engine/board.js`: the engine (plain JS); `tools/build.mjs` turns a spec into
  a HyperFrames project, `tools/render.py` renders it, `tools/release.py` makes
  the release set, `tools/split.py` times the user's recording per line.
- `videos/<folder>/` (spec, script, voice), `projects/<folder>/` (generated) and
  `out/<folder>/` (exports) are local only.
Fonts, music and the logo come from the app; SFX from `social/assets/sfx`.
Example: `social/whiteboard/videos/wb-01-alpha-ar`.

## Git

Same rules as the `social-media` skill: videos stay local. In
`social/whiteboard/`, `videos/`, `projects/`, `out/` and `node_modules/` are
git-ignored (its own `.gitignore`); only the engine, the tools, `package.json`,
the README, the `wb_marker` SFX (`social/tools/synth_social_sfx.py`) and this
skill go in git.

## Fixed decisions

- **Pace:** not limited to 1 minute; take time. About half the video is the
  letter itself, then the words. The voice sets the length (Alpha: 101 s).
- **Order:**
  1. *Letter panel:* the pen writes the big capital (hook) → "ده حرف …" → name
     (red underline) → its rank ("الحرف رقم ١") → its two forms (كبير / صغير)
     → what it looks like, both forms (e.g. Ⲁⲁ ≈ A a).
  2. *Facts panel:* its sound (بينطق: آ, ⲁ = ا), vowel or consonant (حرف متحرك
     in a red box, ا و ي), its number value (ⲁ with a red bar = ١), and a
     church / Bible fact when there is a true one (e.g. Alpha and Omega).
  3. *Arabic words:* 1–2 words that start with the letter's sound: word →
     drawing → the word spelled in Coptic letters (the taught letter red).
  4. *Coptic words:* 3–4 words: Coptic (letter red) → how it sounds in Arabic
     letters → drawing → Arabic meaning (blue, optional, e.g. آمين needs none).
  5. A short empty pause, then the recap: zoom out over the whole board, red
     circle round the letter. Another pause, then the end card
     "تابعونا للحرف الجاي!" + logo.
- **Look:** neutral teacher whiteboard, no characters. Black ink, red for the
  taught letter / underlines / boxes / the recap circle, blue for labels,
  titles and meanings. A floating marker, never a hand, and only on screen
  while it writes or draws (it fades out while the narrator talks without
  writing). App fonts: Baloo Bhaijaan 2 (Arabic), Avva Shenouda (Coptic, typed
  with Latin keys — table below); Baloo 2 only for symbols like ≈ or when a
  fact compares with a Latin letter.
- **Safe area:** every word between y 150 and 1540 on every panel, the recap
  zoom-out included (the facts panel shrinks its rows to fit).
- **Board:** 2×2 panels (letter, facts, Arabic words, Coptic words) + end panel
  under them; the camera pans panel to panel (whoosh), zooms out for the recap.
- **Drawings:** Fluent Emoji ids. The pen traces the black high-contrast
  outline, then the same emoji fills in **in colour** (Fluent Emoji Flat). Both
  MIT, installed in `social/whiteboard` (`npm install` there once).
  Never leave drawings black: the user wants them colourful. Find names with
  `node -e "console.log(Object.keys(require('./social/whiteboard/node_modules/@iconify-json/fluent-emoji-flat/icons.json').icons).filter(k=>k.includes('lion')))"`.
- **Audio:** narrator only (no subtitles), marker scratch (`wb_marker`) only
  while the pen moves, a soft pop when each word row finishes, whoosh on pans,
  sparkle on the recap circle, quiet music (`map_theme`).
- **Narration: text only, the user provides the audio.** Claude writes the
  narration text with performance tags and never generates, calls or pays for
  any voice (no ElevenLabs API, no TTS). The user records it in the tool of
  their choice (Alpha: ElevenLabs Eleven v3, voice "Haytham - Dramatic, Warm
  and Friendly") and drops the file in; see step 3. Lively, never monotone.
- **Script style:** spoken Egyptian (Cairo), warm teacher talking to kids 7–9,
  short sentences. Coptic words are said the church way. Say "Coptic", never
  "Bohairic". Only true facts: check them (letters.json for name/sound/order).

## Spec (`whiteboard.json`)

```jsonc
{
  "lang": "ar", "letter": "alpha",              // id in app/assets/content/letters.json
  "music": {"track": "map_theme", "volume": 0.06},
  "intro": {"say": [l1, l2, l3], "rank": "الحرف رقم ١", "capital": "كبير", "small": "صغير"},
  "facts": [                                    // one per script line
    {"panel": "letter", "say": "...", "rows": [[{"t": "Aa", "s": "cop"}, {"t": "≈", "s": "en"}, {"t": "A a", "s": "en", "c": "blue"}]]},
    {"say": "...", "rows": [[{"t": "حرف متحرك", "s": "ar", "c": "red", "box": true}], ...]},
    {"say": "...", "rows": [[{"t": "a", "s": "cop", "over": true}, {"t": "=", "s": "en"}, {"t": "١", "s": "ar", "c": "red"}]]}
  ],
  "sections": [
    {"group": "ar", "title": "كلمات عربي", "say": "...", "words": [{"word": "أسد", "coptic": "acad", "icon": "lion", "say": "أسد!"}]},
    {"group": "cop", "title": "كلمات قبطي", "say": "...", "words": [{"coptic": "ajjeloc", "ar": "أنجيلوس", "meaning": "ملاك", "icon": "baby-angel", "say": "..."}]}
  ],
  "recap": {"say": "..."}, "end": {"say": "...", "text": "تابعونا للحرف الجاي!"}
}
```

Every `say` is one script line (without tags), in board order. Row parts are in
reading order: `s` = font (ar / cop / en), `c` = red / blue, `box` = red box,
`over` = red bar over it (a Coptic number).

## Workflow

Ask the user one MCQ at a time (AskUserQuestion) when something is unclear.

1. **Script first, before any implementation:** show the user a table per
   panel: line number, what the narrator says, what the pen writes/draws.
   Include the letter facts, 1–2 Arabic words and 3–4 Coptic words (with
   Coptic spelling, Arabic transliteration, meaning, icon). Ask (MCQ) approve /
   change lines / remove facts; apply changes and confirm the final text.
2. **Spec:** create `social/whiteboard/videos/wb-NN-<letter>-ar/whiteboard.json` (next NN).
3. **Narration text (the user records the audio):** write the whole script as
   **one copy-paste block**, one line per `say`, **full of performance tags**
   in square brackets ([excited], [gasps], [whispers], [curious], [playfully],
   [chuckles], [laughs], [proudly], [softly], [amazed], [storytelling],
   [reverent], [short pause], [dramatic pause]...; several per line, so it
   never sounds monotone) and `[long pause]` at the end of every line (the gap
   that lets split.py cut it). Vowel marks on tricky Coptic words
   (أنْجِيلوس). Save it in `social/whiteboard/videos/<folder>/script.md`, give
   it to the user, and **stop**: do not generate any audio. When the user
   gives the recording, save it as `voice/full.mp3` and run
   `tools/.venv/bin/python social/whiteboard/tools/split.py <folder>` (repo
   root): it transcribes with Whisper, matches each `say` and cuts in the
   pauses → `voice/take.mp3` + `take.json`. Check the printed spans line up.
   The `say` strings in whiteboard.json are the script lines without tags.
4. **Build and preview (HyperFrames):**
   ```bash
   node social/whiteboard/tools/build.mjs <folder>     # -> social/whiteboard/projects/<folder>/ + timing.json
   tools/.venv/bin/python social/whiteboard/tools/render.py social/whiteboard/projects/<folder> social/whiteboard/out/<folder>/draft.mp4
   ```
   Check frames (`npx hyperframes snapshot --at …` in the project, or a contact
   sheet from the MP4) for clipped text, overlaps and empty panels, check no
   frame flashes (a frame that differs from both neighbours while they match
   each other), and run `npx hyperframes check` in the project. Never
   hand-edit the generated project: change the spec or the engine and rebuild.
   Pacing knobs in `engine/board.js`: `PAD`, `GAP`, `PAUSE`, text/icon durations.
5. **Release** (when the user approves):
   ```bash
   tools/.venv/bin/python social/whiteboard/tools/release.py <folder> --thumb <seconds> [--story-beats 0-4] [--speed 1.5]
   ```
   → `social/whiteboard/out/<folder>/`: `video.mp4` (full quality: CRF 12 slow,
   AAC 320k), `thumbnail.jpg` (pick a moment with the whole letter panel
   written), `story.mp4` (the hook, fast and packed: the first beats, by
   default the letter panel and its sound (`say` lines 0–4), with every silence
   cut (only the voice, the pen drawing and camera moves are kept) and played
   at 1.5× with the voice's pitch kept; Alpha: 27 s of video → 15 s story).
   `--story-only` re-makes just the story. Then write `post.md` there: a short **TikTok** caption (hook
   line, 1–2 facts, a few words, call to follow, ~10 hashtags) and a longer
   **Instagram** caption (the facts as ✨ lines, the words with emoji
   `عربي ← قبطي`, "احفظ الفيديو وابعته…", call to follow, ~13 hashtags), both
   in Egyptian Arabic with Coptic letters, plus a story note (link sticker,
   «الفيديو كامل على البروفايل 👆»). Send the user the files.

## Rendering on this Mac

There is no full ffmpeg here. `tools/render.py` renders a PNG sequence with
HyperFrames (`npx hyperframes render --format png-sequence`, audio tags
removed), mixes every `<audio>` itself with numpy and encodes with the ffmpeg
bundled in `social/remotion/node_modules` (no filters needed). For
`npx hyperframes check` / `preview` / `snapshot`, put the wrappers it writes to
`$TMPDIR/ffwrap` on PATH. If the user installs ffmpeg (`brew install ffmpeg`),
`npx hyperframes render` works directly.

## Avva Shenouda keys (Coptic font)

ⲁ a · ⲃ b · ⲅ j · ⲇ d · ⲉ e · ⲋ 6 · ⲍ z · ⲏ 3 · ⲑ 0 · ⲓ i · ⲕ k · ⲗ l · ⲙ m ·
ⲛ n · ⲝ 7 · ⲟ o · ⲡ p · ⲣ r · ⲥ c · ⲧ t · ⲩ v · ⲫ f · ⲭ x · ⲯ y · ⲱ w ·
ϣ 2 · ϥ 4 · ϧ q · ϩ h · ϫ g · ϭ s · ϯ 5. Capitals: the uppercase key
(digits: ⲋ ^, ⲏ #, ⲑ ), ⲝ &, ϣ @, ϥ $, ϯ %). Source: `app/assets/content/letters.json`.
Examples: ⲁⲙⲏⲛ `am3n`, ⲁⲅⲅⲉⲗⲟⲥ `ajjeloc`, ⲁϧⲧⲁⲃⲟⲩⲧ `aqtabovt`.
