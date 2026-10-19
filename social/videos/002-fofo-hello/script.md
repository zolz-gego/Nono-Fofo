# 002 · Fofo says hi (demo)

A ~14-second hello from Fofo, the curious little brother: his name, what he
loves, his favorite question and his catchphrase.

**Voice:** `Fofo` (see [../../voices.md](../../voices.md)) · **Model:** Eleven v3 ·
**Stability:** Creative · **Music:** `place_grandpa_house` (from the app)

Fofo sounds softer, slower and more thoughtful than Nono. He's sweet and a bit
shy, and he gets excited when he solves something.

## Option A: all lines in one take

Paste this as one generation. The empty lines make clear pauses between the
lines, so the take can be split automatically. Save it as `full_take.mp3`.
```
[happy] أهلاً! أنا فوفو! [giggles]

[excited] أنا بحب الألغاز، والرسم!

[curious] وبسأل على كل حاجة... ليه؟

[thoughtful] استنى نفكر شوية... [happy] لقيتها!
```

## Option B: one line per generation

Make 2–3 takes of each line, keep the best, download it as **MP3** and save it
in `social/videos/002-fofo-hello/voice/` with the file name shown.

### 1 · `l1_hello.mp3` · Hello (yellow sunburst, Fofo pops up waving)
Feeling: happy, a little shy, ends with a small giggle.
```
[happy] أهلاً! أنا فوفو! [giggles]
```
On screen: أهلاً! أنا فوفو! · *Hi! I'm Fofo!* · pop-up **فوفو / Fofo** ⭐

### 2 · `l2_loves.mp3` · What he loves (blue with bubbles, reading, then drawing)
Feeling: excited and sweet, with a small pause before والرسم.
```
[excited] أنا بحب الألغاز... والرسم!
```
On screen: أنا بحب الألغاز، والرسم! · *I love puzzles, and drawing!* ·
pop-ups **الألغاز / Puzzles** 🧩 and **الرسم / Drawing** 🖌️

### 3 · `l3_why.mp3` · His question (coral sunburst, Fofo looks surprised)
Feeling: curious, wide-eyed; "ليه؟" goes up at the end like a real question.
```
[curious] وبسأل على كل حاجة... ليه؟
```
On screen: وبسأل على كل حاجة… ليه؟ · *And I ask about everything... why?* ·
pop-up **ليه؟ / Why?** ❓

### 4 · `l4_think.mp3` · Catchphrase (green with Coptic letters, thinks, then the light bulb pops)
Feeling: slow and thoughtful ("hmm…"), then a happy "aha!" on لقيتها.
```
[thoughtful] استنى نفكر شوية... [happy] لقيتها!
```
On screen: استنى نفكر شوية… لقيتها! · *Wait, let's think a bit... I've got it!* ·
pop-up **لقيتها! / Got it!** 💡

### End card (no voice)
Logo pops in with the sting sound · **تابعونا! / Follow us!**

## Checklist when the voice arrives

- Each line is under ~4 s (scene ≤ 5 s).
- It sounds clearly younger and softer than Nono.
- Pronounced as Egyptian Arabic (ليه = *leh*, شوية = *shwaya*, لقيتها = *la'etha*).
- Re-render: `cd social/remotion && npm run render -- 002-fofo-hello`
