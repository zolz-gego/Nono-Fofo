# Nono & Fofo: game card prompts (Gemini)

One illustration per game card on the level road. Same tool and workflow as
[character-prompts.md](character-prompts.md):

1. Attach the approved brothers image (`design/reference/nono-fofo-approved.webp`)
   to every prompt, so the style and colors match the characters.
2. Paste the **style block**, then one **game prompt** under it.
3. Save the result as a square PNG (at least 1024 × 1024) with the file name
   in the table, into `app/assets/games/`. Until a file is there, the card shows
   a placeholder icon.

| Game | File |
|---|---|
| صيد السمك / Fish catch | `fishing.png` |
| اكتب الحرف / Write the letter | `writeLetter.png` |
| فرقع البالونة / Pop the balloon | `balloons.png` |
| تحدّى أخوك / Challenge your brother | `challenge.png` |

---

## Style block (paste first, every time)

```
Square game-card illustration for a children's educational app, in the same flat 2D vector cartoon style as the attached reference: thin warm-brown outlines, flat colors with soft shading, rounded friendly shapes, cheerful and simple, readable at small size. Use ONLY this color palette: deep teal #0F4C5C, mist blue #A8DADC, warm sand #EFE6D8, slate teal #4F7C82, cocoa brown #5B4B3A, sunny yellow #FFC845, coral #FF7A5C, leaf green #6CC24A, cream #FFFBF4. Background: soft warm sand #EFE6D8 filling the whole square, with the main subject centered and some space around the edges. No text, no Latin or Arabic letters, no logos, no watermark, no frame or border. Any letters shown must be Coptic letters (like Ⲁ Ⲃ Ⲅ Ⲇ Ⲉ), large and clear in cocoa brown #5B4B3A.
```

## Game prompts

### 1. Fish catch: `fishing.png`

```
A calm blue river scene seen from the side: mist-blue #A8DADC water with gentle deep-teal #0F4C5C waves. Three cute round cartoon fish (one coral, one sunny yellow, one leaf green) swim and jump out of the water, each with a big Coptic letter on its side (Ⲁ, Ⲃ, Ⲅ). A cocoa-brown fishing rod enters from the top corner, its line and hook dangling just above the coral fish. A couple of small bubbles and a tiny reed plant at the edge. Playful and inviting.
```

### 2. Write the letter: `writeLetter.png`

```
A small deep-teal #0F4C5C chalkboard with a cocoa-brown #5B4B3A wooden frame, slightly tilted. On it, a big Coptic letter Ⲁ drawn with dotted cream guide lines, half traced in a bold sunny-yellow #FFC845 line, with small arrows showing the stroke direction. A big chunky sunny-yellow pencil with a coral #FF7A5C eraser leans against the board as if it is writing. A few small sparkles around the letter. Simple, clean and friendly.
```

### 3. Pop the balloon: `balloons.png`

```
Four shiny round party balloons floating up at different heights, in coral #FF7A5C, sunny yellow #FFC845, leaf green #6CC24A and mist blue #A8DADC, each with a curly cocoa-brown string and a big Coptic letter on it (Ⲁ, Ⲃ, Ⲅ, Ⲇ). One balloon in the middle is popping: a cartoon burst shape with small colorful confetti pieces and little star sparkles flying out. Joyful and full of energy.
```

### 4. Challenge your brother: `challenge.png`

```
Using the attached reference for the exact look of both brothers: Nono and Fofo stand face to face in a friendly race pose, each leaning forward with a determined, playful smile, Nono on the left and Fofo on the right. Between them, slightly above, a shiny sunny-yellow #FFC845 trophy cup with a coral #FF7A5C ribbon and small star sparkles. A short cocoa-brown dashed starting line on the ground under their feet. Same clothes, hair and colors as the reference. Fun, friendly competition, not angry.
```
