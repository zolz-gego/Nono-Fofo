---
name: social-media
description: Make Nono & Fofo TikTok / Instagram videos — portrait motion graphics and B-rolls with the app's characters, colors, fonts, music and SFX, Egyptian Arabic voices from ElevenLabs (v3 with emotion tags), Arabic + English captions and keyword pop-ups, rendered with Remotion. Use for any social post, reel, short, script, voice script, or new social asset, and whenever a new image/sound is added for the social videos.
---

# Nono & Fofo social videos

Everything lives in `social/` (map and asset catalog: `social/README.md`).
Motion is Claude's job (Remotion, in code); voices are made by the user in
ElevenLabs from the script Claude writes.

## Fixed decisions

- **Format:** portrait 1080×1920, 30 fps, H.264 MP4. Images also portrait.
- **Audience:** kids 7–9. Short, simple, warm words; no sarcasm, nothing scary.
- **Language:** spoken Egyptian Arabic (Cairo), never MSA. On screen: the Arabic
  line (word-by-word highlight) with the English subtitle under it.
- **Keywords** pop up as cards with an icon, the Arabic word and the English word.
- **Pace:** every scene ≤ 4–5 s. One voice line per scene. Something moves or
  changes at least every ~1.5 s (pose swap, keyword pop, wipe, sticker).
- **Look:** motion graphics on AppColors only (`sunYellow`, `coral`, `mistBlue`,
  `leafGreen`, `deepTeal`, `cream`, `cocoa`…), app fonts (Baloo Bhaijaan 2 /
  Baloo 2 / Avva Shenouda for Coptic). Backgrounds: `rays`, `dots`, `letters`.
- **Voice prompts:** ElevenLabs blocks voices described as children. Voice
  Design prompts describe an adult voice actor doing a bright cartoon voice,
  never an age or "boy/child" (see `social/voices.md`).
- **Talking:** no mouth animation. Characters bob/squash with the voice
  loudness and switch poses on key words.
- **Branding:** start straight in the action; small logo watermark; end card
  with the logo sting and **تابعونا! / Follow us!**
- **Story world:** stay in character (see the app's story: Nono 9, always
  running, "يلا بينا!"; Fofo 6, curious, "استنى نفكر شوية"; Grandpa's Coptic book,
  letters scattered across Egypt). Say "Coptic", never "Bohairic".
- **Safe areas:** keep text inside x 70–930 and y 150–1560 (TikTok/Reels UI).

## Workflow for a new video

1. **Agree the idea** with the user (one question at a time if anything is unclear).
2. **Create** `social/videos/<NNN-slug>/` (next number) with:
   - `script.md`: same layout as `001-nono-hello/script.md`: voice, model,
     then per line: number, file name `lN_<word>.mp3`, scene description,
     "Feeling:" note, the v3 text in a code block (tags per `social/voices.md`),
     and the on-screen Arabic / English / keywords. End with the checklist.
   - `video.json`: the scenes (format in `social/remotion/src/types.ts`).
     Each `line.say` must equal the script text; `estimate` ≈ 0.28 s per Arabic
     word + 0.3 s per tag sound. Poses come from `app/assets/characters/manifest.json`.
   - an empty `voice/` folder (keep it with a `.gitkeep`).
3. **Draft render** without voices so the user can see the motion:
   `cd social/remotion && npm run render -- <NNN-slug>` and check stills with
   `npm run still -- <NNN-slug> <seconds>` (look at them with Read). The sync step
   warns about missing voices, unknown poses or sfx; fix all but "no voice yet".
4. **Hand the script over:** point the user to `script.md` and ask them to drop the
   MP3s in `voice/`.
5. **When voices arrive:** re-render. Timing follows the real audio automatically.
   Listen-check by reading durations from the sync/render output; if a line runs
   over ~4.5 s, split it into two scenes or ask for a faster take. If a caption's
   word highlight drifts, add `words` (start second of each Arabic word).
6. Add the video to the **Videos** table in `social/README.md` with its status.

## Adding resources (always keep the catalog up to date)

Whenever a new resource is created or added for the social videos, put it in
`social/assets/` and register it in **both** places in the same change:
`social/assets/manifest.json` and the **Asset catalog** in `social/README.md`.

- **Sound effect:** add an `@sfx("mg_…", "description", vol)` entry in
  `social/tools/synth_social_sfx.py` (reuse `tools/audio/dsp.py` parts), run
  `tools/.venv/bin/python social/tools/synth_social_sfx.py mg_…` (it rewrites the
  `sfx` section of the manifest), then add the README row. Prefer an existing
  app or social SFX first; add new ones when a moment really needs it.
- **Image / illustration / background:** save it portrait-friendly (PNG with
  transparency for cut-outs) as `social/assets/images/<kebab-name>.png`, add an
  `images` entry to the manifest (`file`, `desc`, `width`, `height`, `source`),
  and a README row. Use it in Remotion with `staticFile('social/images/<file>')`.
- **Icon for keyword cards:** Font Awesome only; add it to
  `social/remotion/src/icons.ts` and to the README icon list.
- **Voice / character / music / app SFX / colors / fonts:** these belong to the
  app. Add them in the app (its own pipeline, `design/` prompts and manifests);
  `npm run sync` picks them up for the videos automatically. Never copy app
  assets into `social/assets`.
- New reusable motion (a sticker, a transition, a new background pattern) goes
  in `social/remotion/src/components/` and gets a line in the README.

## Remotion notes

- Compositions are generated from `social/videos/*`: id `v<folder>`.
- `scripts/sync-assets.mjs` copies app + social assets into `remotion/public/`
  and writes `src/generated/data.ts` (colors, poses, sfx, music, videos). Both
  are git-ignored; never edit them.
- Automatic sounds: wipe (`mg_scene_swipe`), entrance (`mg_whoosh_in` /
  `mg_boing` for `pop`), pose swap (`mg_pose_swap`), keyword (`mg_keyword_pop`/`_2`),
  end card (`mg_logo_sting`). Extra sounds: `sfx` in the scene, any app or
  social id. Music: an app track id, low and ducked under voices.
- Rendered files go to `social/out/` (git-ignored). Pin exact npm versions.
