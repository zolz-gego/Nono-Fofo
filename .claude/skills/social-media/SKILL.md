---
name: social-media
description: Make Nono & Fofo TikTok / Instagram videos — portrait motion graphics and B-rolls with the app's characters, colors, fonts, music and SFX, Egyptian Arabic voices from ElevenLabs (v3 with emotion tags), Arabic + English captions and keyword pop-ups, rendered with Remotion. Use for any social post, reel, short, script, voice script, or new social asset, and whenever a new image/sound is added for the social videos.
---

# Nono & Fofo social videos

Everything lives in `social/` (map and asset catalog: `social/README.md`).
Motion is Claude's job (Remotion, in code); voices are made by the user in
ElevenLabs from the script Claude writes.

## Git

- **No new branch.** Social video work stays on whatever branch is checked out;
  don't create a branch for it (this overrides the per-chat branch rule in
  `CLAUDE.md` for social work).
- **Only resources and the skill go in git:** `social/assets/` (with its
  `manifest.json` and the README asset catalog), shared engine/tool changes in
  `social/remotion/` and `social/tools/`, and this skill.
- **Videos never go in git.** `social/videos/` (scripts, `video.json`, voices),
  `social/previews/`, `social/out/` and the logo intro (`social/remotion/src/intro/`,
  `social/tools/synth_intro.py`) are git-ignored and stay on this machine. Never
  `git add -f` them. Local-only compositions are registered through
  `src/generated/local.ts` (written by `npm run sync` when `src/intro/` exists).

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
- **The brothers' dynamic (use it in every script with both of them):** Nono is
  impulsive (مندفع): he jumps in first, answers too fast and often gets it
  wrong (wrong letter, wrong word, silly guess). Fofo catches the mistake and
  gives him the right answer in a funny, loving way: a cheeky "لأ يا نونو!",
  a silly comparison, a giggle, a playful tease, then the correct answer said
  clearly so kids learn it. Nono laughs at himself, repeats it right and cheers
  ("يلا بينا!"). Never mean, never makes Nono look stupid. Mistakes are fun
  and fixed. Typical beat: Nono's wrong answer (`wrong` / `surprised` pose,
  gentle `wrong_1` or `mg_slide_down`) → Fofo corrects (`hint` pose, keyword
  pop with the right answer) → Nono gets it (`cheer`, `correct_1`).
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
   - an empty `voice/` folder.
3. **Draft render** without voices so the user can see the motion:
   `cd social/remotion && npm run render -- <NNN-slug>` and check stills with
   `npm run still -- <NNN-slug> <seconds>` (look at them with Read). The sync step
   warns about missing voices, unknown poses or sfx; fix all but "no voice yet".
4. **Hand the script over:** point the user to `script.md` and ask them to drop the
   MP3s in `voice/`.
5. **When voices arrive:** if the user sends one take with all lines, split it:
   `tools/.venv/bin/python social/tools/split_voice.py <NNN-slug> <take.mp3>`
   (keeps it as `voice/full_take.mp3`, writes `voice/<line id>.wav`). If a line
   has its own long pause (e.g. "... ليه؟"), the auto split fails: find the line
   times from the loudness envelope and pass `--lines 0-2.8,2.9-5.1,...`. Then set
   `words` for long lines and move keyword `at` onto the spoken word using the
   loudness envelope, and re-render. Timing follows the real audio automatically.
   Listen-check by reading durations from the sync/render output; if a line runs
   over ~4.5 s, split it into two scenes or ask for a faster take. If a caption's
   word highlight drifts, add `words` (start second of each Arabic word).

## When the user says the video is done

When the user says a video is finished ("done", "it's ready", "ship it",
"export it"), do all of this automatically, without asking:

1. **Pick the thumbnail frame:** the most eye-catching moment, with both brothers
   (or the logo) clear and readable, nothing mid-transition or blurred, and no
   flash. Check two or three candidates with `npm run still` and look at them.
2. **Export:** `cd social/remotion && npm run release -- <NNN-slug> <thumb-seconds>`
   (the intro: `intro-portrait`). It writes `social/out/release/<NNN-slug>/`:
   - `video.mp4`: high quality for upload (1080×1920, H.264 CRF 12 slow, AAC 320k).
   - `thumbnail.jpg`: the full-size cover frame.
   Check the result with `npx remotion ffprobe` (size, fps, duration, audio).
3. **Write `post.md`** in the same folder with captions for both platforms:
   - **Instagram (Reels):** a hook line, 2–3 short lines on what happens, and a
     call to action (تابعونا / Follow us), first in Egyptian Arabic (never MSA,
     same voice as the brothers) and then the same in English. Then exactly 5
     hashtags.
   - **TikTok:** shorter. One Arabic line plus one English line (TikTok shows
     little before "more"), then 5 hashtags including `#fyp`.
   - Always include `#نونو_وفوفو` and `#NonoAndFofo`. Pick the rest from the video's
     topic, mixing Arabic and English: `#اللغة_القبطية` `#LearnCoptic`
     `#CopticLanguage` `#تعليم_الأطفال` `#KidsLearning` `#قبطي` `#مصر` `#Egypt`
     `#KidsApp` `#EducationalGames` `#تعليم_ممتع`. End with a short list of extra
     hashtags to swap in.
   - Kid-safe and warm. A few emojis are fine. Say "Coptic", never "Bohairic".
     Don't promise downloads, prices or dates unless the user gave them.
4. **Deliver:** send `video.mp4`, `thumbnail.jpg` and `post.md` to the user, and
   paste both captions in the reply so they can copy them. All of it stays local
   (`social/out/` is git-ignored).

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
  in `social/remotion/src/components/` and gets a line in the README. Story
  props (golden book, Egypt map, letter card, slots, speed lines, shake, arrow,
  running letter, little statues, dizzy stars, panting, letter ≈ Latin
  comparison, confetti) already exist in `Props.tsx`: use them through `props`
  in `video.json`.
- **Guest characters** (e.g. Ramses): cut-out PNG poses in `social/assets/images/`,
  registered under `characters` in `social/assets/manifest.json`, a voice in
  `social/voices.md`, and a row in the README catalog. Missing poses render as a
  placeholder so drafts work before the art arrives. Image prompts for a video go
  in its folder (`images.md`), in the brothers' style.

## Remotion notes

- Compositions are generated from `social/videos/*`: id `v<folder>`.
- `scripts/sync-assets.mjs` copies app + social assets into `remotion/public/`
  and writes `src/generated/data.ts` (colors, poses, sfx, music, videos). Both
  are git-ignored; never edit them.
- Automatic sounds: wipe (`mg_scene_swipe`), entrance (`mg_whoosh_in` /
  `mg_boing` for `pop`), pose swap (`mg_pose_swap`), keyword (`mg_keyword_pop`/`_2`),
  end card (`mg_logo_sting`). Extra sounds: `sfx` in the scene, any app or
  social id. Music: an app track id, low and ducked under voices.
- Rendered files go to `social/out/` (git-ignored); finished posts go to
  `social/out/release/<NNN-slug>/`. Pin exact npm versions.
