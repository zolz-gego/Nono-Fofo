# 001 · Nono says hi (demo)

A 12-second hello from Nono to check the whole pipeline: voice, talking
bounce, captions, keyword pop-ups, sounds and the end card.

**Voice:** `Nono` (see [../../voices.md](../../voices.md)) · **Model:** Eleven v3 ·
**Stability:** Creative · **Music:** `map_theme` (from the app)

## Lines for ElevenLabs

Paste each block as its own generation (Text to Speech). Make 2–3 takes, keep
the best, download as **MP3** and save it in
`social/videos/001-nono-hello/voice/` with the file name shown.

### 1 · `l1_hello.mp3` · Hello (yellow sunburst, Nono runs in and waves)
Feeling: super happy to see you, a bit out of breath from running.
```
[excited] أهلاً أهلاً! [giggles]
```
On screen: أهلاً أهلاً! · *Hello, hello!*

### 2 · `l2_name.mp3` · Name (coral sunburst, Nono pops up cheering)
Feeling: proud, chest out, big smile.
```
[proudly] أنا نونو!
```
On screen: أنا نونو! · *I'm Nono!* · pop-up **نونو / Nono** ⭐

### 3 · `l3_love.mp3` · What he loves (blue with bubbles, runs then celebrates)
Feeling: happy, then extra excited on "football". Small pause after أجري.
```
[happily] أنا بحب أجري... [excited] وبحب الكورة أوي!
```
On screen: أنا بحب أجري، وبحب الكورة أوي! · *I love running, and I really love football!* ·
pop-ups **أجري / Run** 🏃 and **الكورة / Football** ⚽

### 4 · `l4_lets_go.mp3` · Catchphrase (green with Coptic letters, Nono jumps)
Feeling: big shout, full energy, his catchphrase.
```
[shouting] يلا بينا!
```
On screen: يلا بينا! · *Let's go!*

### End card (no voice)
Logo pops in with the sting sound · **تابعونا! / Follow us!**

## Checklist when the voice files arrive

- Each line is under ~4 s (scene ≤ 5 s).
- Pronounced as Egyptian Arabic (بحب = *baḥebb*, أوي = *awi*).
- No clicks, breaths or silence longer than ~0.3 s at the start/end.
- Re-render: `cd social/remotion && npm run render -- 001-nono-hello`
