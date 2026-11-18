---
name: tutorial-video
description: Make Arabic "how to play" tutorial videos (TikTok / Reels, 9:16) of the Nono & Fofo website, one game per video — Playwright records the live site as a phone (taps, typing, gameplay), then Remotion replays it with zoom-ins, the rest of the screen blurred, a glowing ring and a cartoon finger on each step, click/whoosh/typing sounds, energetic music, pop stickers, the user's own recorded voice with captions, the logo intro and a website end card. Use whenever the user asks for a tutorial, walkthrough, how-to-play or demo video of the website or one of its games.
---

# Website tutorial videos

A series of short Arabic videos that show kids (and parents) how to play each
game on https://zolz-gego.github.io/Nono-Fofo/, one game per video, in the
order of the games map (Level 1: fishing first, then the next stops).

Built on the social video engine (`social/remotion`), so read the
`social-media` skill's **Git**, look, safe-area and release rules too: they
apply here unless this skill says otherwise.

## Git

Same as social videos: **no new branch**. Only the engine, tools, assets and
this skill go in git. `social/tutorials/` (specs, scripts, recordings,
voices) and `social/out/` are git-ignored and stay on this machine.

## Fixed decisions (agreed with the user)

- **Format:** 1080×1920, 30 fps. The site is recorded as a **phone**
  (390×844 CSS px, 3× pixels, touch, Arabic locale) on the **live site**.
- **Voice:** the user records it from the tagged script Claude writes (one
  take, pauses between lines). Claude never generates audio. Spoken Egyptian
  Arabic, warm older-sibling tone, short sentences. Say "Coptic", never "Bohairic".
- **Every step:** the camera zooms to the element, the rest of the screen is
  blurred and dimmed, a glowing sunYellow ring pulses around it, and a cartoon
  finger (Font Awesome `hand-pointer`, white with a cocoa outline) slides in and
  taps it with a ripple.
- **Narrated steps freeze:** the recording stops just before the tap while the
  voice explains, then the finger taps and the recording plays on. Gaps
  (loading, animations) are sped up.
- **Energetic style:** fast pacing (short holds, sped-up gaps), the
  `game_race` music at ~0.22 (ducked under the voice), coral/sunYellow rays
  behind the title and the phone, the title slams in with a shake, zooms land
  with a small overshoot, every tap kicks the camera, and a sticker pops after
  each catch: **صح!** (green, `correct_1`), **غلط!** (coral, camera shake,
  `wrong_1` + `mg_boing` + `wrong_2` — the "wrong" music), **برافو!** with
  confetti on the result card. Voice lines are short and excited.
- **Setup is a fast recap in every video** (`"fast": true` steps):
  Level 1 → type the name → pick the buddy → Let's play, sped up with
  light highlights under one voice line. **Don't show or mention the
  language** (the recorder opens the site in Arabic already). Then the game part at normal speed.
- **Demo data:** name **مينا**, plays with **Nono**, letter **ⲁ (Alpha)**
  unless the user picks others. After the setup: pick the game, pick its
  option (letter…), then **play a short round**: a right action (narrated
  freeze), **a wrong one** (tap, then the referee's reaction highlighted while
  the voice explains), another right one live, then the rest of the round
  happens off camera and the video **jump cuts to the result card** (stars,
  play again / other letter) with its own voice line.
- **Sounds:** `tut_tap` on every tap, `tut_type` per typed letter,
  `tut_zoom_in` / `tut_zoom_out` and `tut_highlight` on narrated steps,
  `mg_whoosh_in` on quick zooms, the sticker sounds above, upbeat music
  (`game_race`). No game audio.
- **Branding:** the release opens with the logo intro (`RELEASE_INTRO`); a
  title card ("إزاي تلعب …؟" + English, logo, both brothers); the end card
  with the logo sting, **"اللينك في البايو!" / "Link in bio!"** and تابعونا.
  **No website address on screen or in the voice** while the address isn't
  final (leave `end.link` out; set it only when the user says the link is final).
  Small logo watermark during the recording.
- Arabic captions word by word with the English subtitle under them (same
  `Captions` as the social videos), inside the safe area. **One line per
  subtitle, Arabic and English:** split each line into `chunks`
  (`[{from: <first Arabic word index>, en: "<its English>"}]`, break at
  commas) so each chunk's Arabic (62 px, weight 800, 18 px gaps) and English
  (40 px, weight 700) each fit on one line. Check with
  `cd social/remotion && npm run captions -- <NN-game>`, which measures them in
  Chromium with the real fonts (PIL can't shape Arabic here) and suggests
  splits. It must pass before the draft goes to the user.

## Files

- `social/tutorials/<NN-game>/` (local only)
  - `tutorial.json` — the flow + voice lines (format below)
  - `script.md` — the copy-paste voice block + line table + checklist
  - `voice/` — the user's take, split into `<line id>.wav`
  - `recording/` — `frames/*.jpg` + `recording.json` (made by `npm run record`)
- `social/remotion/scripts/record-tutorial.mjs` — the recorder
- `social/remotion/scripts/tutorial-games/<game>.mjs` — a player per canvas game
- `social/tools/tutorial/find_letters.py` — reads the Coptic letters on cream
  badges in a screenshot (Avva font matching), used by game players
- `social/tools/tutorial/find_hollow.py` — finds the hollow letter on the
  writing game's chalkboard and plans chalk rows over it
- `social/remotion/src/tutorial/` — `types.ts`, `plan.ts` (timeline),
  `Tutorial.tsx` (title card, phone, camera, blur, ring, finger, captions)

## tutorial.json

```json
{
  "game": "fishing",
  "site": "https://zolz-gego.github.io/Nono-Fofo/",
  "music": {"track": "game_race", "volume": 0.22},
  "title": {"ar": "إزاي تلعب صيد السمك؟", "en": "How to play Fishing", "line": {LINE}},
  "steps": [
    {"id": "scroll", "do": "scroll", "find": "^المستوى 1, ", "fast": true, "line": {LINE}},
    {"id": "level1", "do": "tap", "find": "^المستوى 1, ", "fast": true},
    {"id": "name", "do": "type", "text": "مينا", "near": "اسمك", "fast": true},
    {"id": "buddy", "do": "tap", "find": "^نونو نونو$", "fast": true},
    {"id": "start", "do": "tap", "find": "يلا نلعب", "fast": true},
    {"id": "game", "do": "tap", "find": "^صيد السمك ", "line": {LINE}},
    {"id": "letter", "do": "tap", "find": "^a ", "line": {LINE}},
    {"id": "play", "do": "play", "game": "fishing", "letter": "a",
     "catches": [{"ok": true, "line": {LINE}}, {"ok": false, "line": {LINE}}, {"ok": true}],
     "lineAfter": {LINE}, "finish": {"line": {LINE}}}
  ],
  "end": {"ar": "اللينك في البايو!", "en": "Link in bio!", "line": {LINE}}
}
```

`LINE` = `{"id": "l3_game", "say": "<tagged text>", "ar": "<caption>", "en": "<subtitle>", "estimate": 3.6}`
(optional `words`, `chunks` like the social videos). Number lines `l1_…`, `l2_…`
in speaking order. `estimate` ≈ 0.28 s per Arabic word + 0.3 s per tag.

**Steps** (`do`):
- `show` — highlight without tapping.
- `tap` — tap the element. `scroll` — finger-swipe until the element is in
  the upper middle. `type` — type `text` into the focused field (`near`:
  a label above it, used if the field has no box). `wait` — `ms`.
- `play` — a canvas game, run by `tutorial-games/<game>.mjs` (see below).
  `catches`: the actions to show in order (`ok: false` = a wrong one; `line`
  = narrated); `lineAfter` plays over the live play after the last narrated
  one; `finish` keeps playing off camera until the result card shows, then
  the video jump cuts to it (zoom + ring, `finish.line`).
- Options: `fast` (setup recap), `line` (narrated: freeze + full zoom; on a
  fast step it plays over the sped-up group), `zoom`, recorder `settle` /
  `stable` (ms). `end.link` adds a website pill on the end card (only once
  the address is final).

**Finding elements:** Flutter draws on a canvas; the recorder turns on its
accessibility tree and matches `find` (a regex) against each
`flt-semantics` node's label + text, newest/last match on screen wins. To see
the names on a page, run a quick Playwright script that opens the site the
same way, clicks `flt-semantics-placeholder`, and prints every node's
`aria-label`, text and box (the recorder's `nodes()` helper). Examples: the
level cards are "المستوى 1, اتعرّف على الحروف | …", games are "صيد السمك
صيد السمك 1", letter cards are "a الفا" (Avva key first).

## Game players (canvas games)

Games drawn with Flame have no nodes. A player module exports
`play(ctx, step)`, taps the right things and returns `{taps: [{t, point, r,
speed, ok}], shownEnd, finish: {t, rect} | null}` (seconds since the recording started, CSS px; `r` ≈ the target's
radius; `speed` = CSS px/s it moves right, 0 if still; optional `vy` = CSS px/s down,
`rect` = the target's box, `react` = where a wrong action's reaction shows). The video keeps the
ring and finger on a moving target with `speed`.

- **fishing.mjs** — screenshots the water, finds the fish whose badge shows
  `letter` with `find_letters.py --serve`, taps it a little ahead of where it
  swims (fish cross the screen in `swimSeconds` = 14 from
  `app/assets/content/games/fishing.json`), waits `between` ms for the reel.
  `ok: false` taps a fish with another letter. With `finish`, it keeps
  catching until the result card's "العب تاني" button appears and logs the
  card's box.
- **balloons.mjs** — balloons rise from the bottom with the letter on a cream
  circle. Looks twice with `find_letters.py --serve` to measure each balloon's
  rise (`vy`, CSS px/s, < 0) and skip the still bunch the other brother
  holds, then taps a little above it (time the look from when the screenshot
  *returns*, or the ring lands above the balloon). Screenshot the whole
  screen and pass find_letters a `top` fraction: a clipped `page.screenshot`
  leaks into the screencast as flashing frames (the recorder now drops
  frames that are out of time order or another size, as a safety net). Logs `rect` (the whole
  balloon) and `react` (both brothers, highlighted while a wrong one pops).
  Off camera it grabs the highest target first; floated-away targets count as
  mistakes, so the round usually ends on 1 star.
- **writing.mjs** — Grandpa's chalkboard. The step has `actions` instead of
  `catches` (matched by index with what the player logs, each may carry a
  `line`): `show demo` (waits for the chalk demo, box = the letter), `tap size`
  (`find: "^تخين$"`), `tap color` (`pick`: nth chalk stick, top row first),
  `draw fill` (`until: "halfway"` / `"passed"`, the brother's speech bubbles
  are read from the accessibility tree; `live: true` = voice over the sped-up
  colouring instead of a freeze), `draw mess` (`ok: false`: scribble under the
  letter until the warning, then the HUD mess meter is highlighted), `show
  capital`. On a narrated `draw fill`, `bar: LINE` adds a second line while
  the camera flies up to the HUD's coloured bar (sharp, the phone may move
  off the top: `free` marks) and back to the board. On a live one, `cut: 6`
  shows that many recording seconds, then jump cuts to the board passing
  (the whole letter takes too long). `finish.shareAt` (word index of its
  line) makes the pass card's Share button bounce and bubble from that word.
  `finish` colours the capital off camera until the pass card's
  "شارك الرسمة". The letter's inside comes from
  `social/tools/tutorial/find_hollow.py` (closes the dotted outline, keeps the
  faintly filled parts → zigzag chalk rows). The live site is slow per touch
  move (~1.5 s a row), so a recording takes ~3.5 min; the video speeds the
  drawing up and the finger follows the logged `path` (`PATH_LAG` in
  `plan.ts`, because the site paints the chalk late).
- For a new game, write `tutorial-games/<game>.mjs` the same way: read the
  game's code and config (`app/lib/features/games/<game>/`,
  `app/assets/content/games/<game>.json`) to know where things are, find the
  targets (accessibility nodes when the game uses Flutter widgets, or
  `find_letters.py` for letters on cream badges, or a new detector in
  `social/tools/tutorial/`), and tap. Keep it to a short round that shows the
  main move, one correct action narrated (freeze) and a couple live.

## Workflow (one question at a time with the user if anything is unclear)

1. **Agree the game and its demo** (option to pick, how many actions to show).
   Read the game's memory/rules so the voice explains it right.
2. **Write `social/tutorials/<NN-game>/tutorial.json`** (copy the last one;
   setup steps stay the same) and **`script.md`** (copy-paste block, one line
   per voice line in order, full of performance tags; line table; checklist).
3. **Record:** `cd social/remotion && npm run record -- <NN-game>` (~1 min).
   It prints every step's time and box; any "not found on screen" means the
   `find` regex or the wait is off. Check a few frames from
   `recording/frames` (shrink with `sips -Z 600` and Read them): pages fully
   loaded at each tap, the game's catches really happened (counter).
4. **Draft:** `npm run render -- <NN-game>` and stills with
   `npm run still -- <NN-game> <seconds>`. Look at the narrated freezes (target
   centered above the captions, ring on it, finger tip on it), the fast recap
   and a live catch. Fix and re-render.
5. **Hand over the script:** point the user to `script.md`; they drop one
   take in `voice/`. Split it:
   `tools/.venv/bin/python social/tools/split_voice.py <NN-game> <take>`
   (same options as for the social videos: `--gap`, `--lines`). Re-render:
   freezes and holds stretch to the real voice lengths automatically.
   If pauses between lines are as short as those inside lines, transcribe
   the take with mlx-whisper (`tools/.venv`, model
   `mlx-community/whisper-large-v3-turbo`, `language='ar'`,
   `word_timestamps=True`). There's no ffmpeg, so pass it a 16 kHz mono array
   made with `afconvert`. Cut with `--lines` at the pauses between the
   script's lines, then store each line's word times (s from its cut start,
   ≥ 0) as `words` in `tutorial.json`. Captions and `shareAt` use those times.
6. **When the user says it's done:** follow the social-media skill's "When
   the user says the video is done" (release with `npm run release --
   <NN-game> <thumb-seconds>` — the logo intro is added; thumbnail on the
   title card or a clear zoomed step; `post.md` with Instagram + TikTok
   captions, "اللينك في البايو" / "Link in bio" while the address isn't final,
   and `#نونو_وفوفو` `#NonoAndFofo`).
7. **Upload to Drive** (automatic, right after `post.md`, no need to ask):
   `python3 social/tools/tutorial/upload.py <NN-game>` copies `video.mp4`,
   `thumbnail.jpg` and `post.md` to `gdrive:Tutorials/<NN-game>/` with rclone
   (remote `gdrive:`). Re-run it after any change to the release set. Then
   send the user the files, paste both captions, and say they're on Drive.

## Notes

- Re-record whenever the website changes (the recording is of the live site).
  `npm run sync` replaces the old frames in `remotion/public/tutorials/`.
- Timing knobs live at the top of `src/tutorial/plan.ts` (lead/tail around a
  voice, how much gaps are sped up, gameplay kept after the last catch).
- Look knobs (phone size, where targets are brought to, blur, ring, finger)
  live at the top of `src/tutorial/Tutorial.tsx`.
- New sounds for tutorials go in `social/tools/synth_social_sfx.py` (`tut_…`)
  and the README catalog, like any social sound.
