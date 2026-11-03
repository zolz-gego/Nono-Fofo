---
name: whiteboard-letter
description: Make a whiteboard-animation reel (TikTok / Instagram, ~80–110 s) that teaches ONE Coptic letter in Egyptian Arabic — a marker (no hand) writes and draws on a white board in sync with the user's ElevenLabs narration; mostly about the letter itself (its name, rank, two forms, look, sound, vowel or not, number value, a church fact), then 1–2 Arabic words and 3–4 Coptic words with colour drawings, Coptic spellings and Arabic transliterations, a recap and a follow end card. Always built and rendered with HyperFrames, and released with a thumbnail, TikTok + Instagram captions and a story hook. Use whenever the user asks for a whiteboard / letter explainer video for a Coptic letter.
---

# Whiteboard letter videos

One Coptic letter per video, portrait 1080×1920, 30 fps, **Arabic only** (no
English words, no English narration, no Latin transliterations on the board).
**Always HyperFrames, never Remotion**: the engine is
`social/tools/whiteboard-hf/board.js` (plain JS), `social/tools/wb_hyperframes.mjs`
turns a spec into a HyperFrames project, `social/tools/hf_render.py` renders it.
Fonts, music and the logo come from the app; SFX from `social/assets/sfx`.
Example: `social/videos/wb-01-alpha-ar`.

## Git

Same rules as the `social-media` skill: videos stay local. `social/videos/wb-*`
(spec, voice), `social/hyperframes/` (generated projects) and `social/out/` are
git-ignored; only the engine and tools (`social/tools/whiteboard-hf/`,
`wb_hyperframes.mjs`, `hf_render.py`, `wb_release.py`, `wb_split.py`,
`wb_tts.py`, `wb_marker` in `synth_social_sfx.py`), assets and this skill go in git.

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
  MIT, installed in `social/tools/whiteboard-hf` (`npm install` there once).
  Never leave drawings black: the user wants them colourful. Find names with
  `node -e "console.log(Object.keys(require('./social/tools/whiteboard-hf/node_modules/@iconify-json/fluent-emoji-flat/icons.json').icons).filter(k=>k.includes('lion')))"`.
- **Audio:** narrator only (no subtitles), marker scratch (`wb_marker`) only
  while the pen moves, a soft pop when each word row finishes, whoosh on pans,
  sparkle on the recap circle, quiet music (`map_theme`).
- **Narrator:** the user generates it in ElevenLabs (Alpha used **Haytham -
  Dramatic, Warm and Friendly**, Eleven v3); see step 3. Lively, never monotone.
- **Key:** `ELEVENLABS_API_KEY` lives in git-ignored `social/.env`. Never ask
  the user for it.
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
2. **Spec:** create `social/videos/wb-NN-<letter>-ar/whiteboard.json` (next NN).
3. **Voice (the user makes it):** give the user the whole script as **one
   copy-paste block** for ElevenLabs **Eleven v3** (Stability Creative), one
   line per `say`, **full of v3 tags** ([excited], [gasps], [whispers],
   [curious], [playfully], [chuckles], [laughs], [proudly], [softly],
   [amazed], [storytelling], [short pause], [dramatic pause]...) so it never
   sounds monotone, and `[long pause]` at the end of every line. Also save it
   in `social/videos/<folder>/script.md`. The user saves the result as
   `voice/full.mp3`; then run
   `tools/.venv/bin/python social/tools/wb_split.py <folder>` (repo root): it
   transcribes with Whisper, matches each `say` and cuts in the pauses →
   `voice/take.mp3` + `take.json`. Check the printed spans line up.
   (`tools/wb_tts.py` can record a take through the API instead, Fatima's
   voice, but the user prefers making the voice themself.)
4. **Build and preview (HyperFrames):**
   ```bash
   node social/tools/wb_hyperframes.mjs <folder>     # -> social/hyperframes/<folder>/ + timing.json
   tools/.venv/bin/python social/tools/hf_render.py social/hyperframes/<folder> social/out/<folder>.mp4
   ```
   Check frames (`npx hyperframes snapshot --at …` in the project, or a contact
   sheet from the MP4) for clipped text, overlaps and empty panels, check no
   frame flashes (a frame that differs from both neighbours while they match
   each other), and run `npx hyperframes check` in the project. Never
   hand-edit the generated project: change the spec or the engine and rebuild.
   Pacing knobs in `board.js`: `PAD`, `GAP`, `PAUSE`, text/icon durations.
5. **Release** (when the user approves):
   ```bash
   tools/.venv/bin/python social/tools/wb_release.py <folder> --thumb <seconds> --story-until "<phrase>"
   ```
   → `social/out/release/<folder>/`: `video.mp4` (full quality: CRF 12 slow,
   AAC 320k), `thumbnail.jpg` (pick a moment with the whole letter panel
   written), `story.mp4` (the hook: the opening, cut just after a phrase that
   leaves them curious, ideally a question, around 10 s; `--story <s>` for a
   fixed length). Then write `post.md` there: a short **TikTok** caption (hook
   line, 1–2 facts, a few words, call to follow, ~10 hashtags) and a longer
   **Instagram** caption (the facts as ✨ lines, the words with emoji
   `عربي ← قبطي`, "احفظ الفيديو وابعته…", call to follow, ~13 hashtags), both
   in Egyptian Arabic with Coptic letters, plus a story note (link sticker,
   «الفيديو كامل على البروفايل 👆»). Send the user the files.

## Rendering on this Mac

There is no full ffmpeg here. `hf_render.py` renders a PNG sequence with
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
