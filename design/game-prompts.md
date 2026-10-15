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

---

## Fishing game art (صيد السمك)

All three are done (2026-10-16). To regenerate any of them, use the prompts
below, then:

| What | Save the original as | Then run |
|---|---|---|
| Fish (one orange fish; the script makes the 8 colors) | `design/reference/fishing/fish.webp` | `tools/.venv/bin/python tools/games/process_fishing.py` |
| Nile background | `design/reference/fishing/nile.webp` | same script; if the banks or waterline move, update `backgroundMarks` in `app/assets/content/games/fishing.json` |
| Nono / Fofo fishing poses (one sheet each: "fish" left, "reel" right) | `Characters/Nono Fishing.webp`, `Characters/Fofo Fishing.webp` | `tools/.venv/bin/python tools/characters/process_poses.py` (check the `PICK` points if the layout of the sheet changes) |

If the code-drawn fallbacks are ever needed again, empty `fishImages` or
remove the background file.

Fish need a **transparent background** (or a flat sand background that is
removed afterwards), must **face right**, and must have an **empty cream circle**
in the middle of the body: the game writes the letter there.

### Fish (one per color, 8 colors)

Generate once per color: coral #FF7A5C, sunny yellow #FFC845, leaf green #6CC24A,
lilac #B57EDC, pink #FF9FC4, orange #FF9F43, sky blue #5EC8E5, mint #3FBFA0.

```
A single cute cartoon fish for a children's game, flat 2D vector style matching the attached reference: thin warm-brown #5B4B3A outlines, flat colors with soft shading, rounded friendly shapes. Side view, the fish faces RIGHT. Plump round body in [COLOR NAME + HEX], slightly darker fins and a swishy tail, a lighter belly, one big shiny friendly eye, a small happy smile and a soft pink cheek. In the middle of the body there is a large EMPTY plain cream #FFFBF4 circle with a thin brown outline (about half the body height) — leave it completely empty, no letter, no pattern inside. Whole fish visible, centered, nothing else in the picture. Plain flat background in one solid color (pure white) so it can be cut out. No text, no letters, no watermark.
```

### Nile background (wide, landscape)

```
Wide landscape (16:9) background for a children's fishing game, flat 2D vector cartoon style matching the attached reference: thin warm-brown outlines, flat colors with soft shading, cheerful and simple. Side view of the Nile in Egypt on a sunny day. Top 45%: soft light-blue sky with a few round cream clouds and a soft yellow sun; on the far bank, a thin strip of green fields with a few date palms and a small white felucca with a triangular sail. On the LEFT edge and the RIGHT edge, a small grassy bank of earth sticks out over the water (a child will stand on each one, so keep them flat and empty). Bottom 55%: the river seen from the side as a cut-away, like an aquarium: light turquoise water near the surface getting deeper teal #0F4C5C toward the bottom, a few bubbles, some green reeds at the corners and a sandy river bed with pebbles at the very bottom. Keep the middle of the water EMPTY (fish will swim there) and keep the top-center of the sky calm and empty (a score card goes there). Use this palette: deep teal #0F4C5C, mist blue #A8DADC, warm sand #EFE6D8, slate teal #4F7C82, cocoa brown #5B4B3A, sunny yellow #FFC845, leaf green #6CC24A, cream #FFFBF4. No characters, no fish, no text, no watermark.
```

### Fishing poses (Nono and Fofo)

Use the same workflow as [character-prompts.md](character-prompts.md) (attach
the approved reference, same style block). Two poses per brother, full body,
plain background, facing RIGHT (toward the water):

```
Using the attached reference for the exact look, clothes and colors: [NONO / FOFO] standing, full body, turned three-quarters to the RIGHT, holding a simple brown wooden fishing rod (صنارة) with both hands at hip height; the rod points up and to the right, at about 35° above horizontal, and its tip reaches beyond his head height. No line, no hook (the game draws them). Pose 1 "fish": calm and focused, looking at the water with a small hopeful smile. Pose 2 "reel": leaning back a little, pulling the rod up with an excited big smile, as if a fish just bit. Same flat 2D style, thin warm-brown outlines. Plain solid white background, no shadow, no text.
```
