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
| امسك البالونة / Catch the balloon | `balloons.png` |
| كروت جدو / Grandpa's Cards | `cards.png` |
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

### 3. Catch the balloon: `balloons.png`

```
Four shiny round helium balloons floating up at different heights, in coral #FF7A5C, sunny yellow #FFC845, leaf green #6CC24A and mist blue #A8DADC, each with a thin curly cocoa-brown string and a big Coptic letter on it (Ⲁ, Ⲃ, Ⲅ, Ⲇ). A child's hand reaches up from the bottom edge and holds the string of the coral balloon. A few small star sparkles around. Joyful and full of energy.
```

### 5. Grandpa's Cards: `cards.png`

```
Four chunky rounded playing cards, centered, arranged in a loose playful fan as if just dealt, slightly overlapping and tilted at different angles. The two cards in the back are face down, with deep-teal #0F4C5C backs, a thin mist-blue #A8DADC border and a simple mist-blue diamond pattern. The two cards in front are flipped face up, cream #FFFBF4 with a thick coral #FF7A5C border, one showing a big capital Coptic letter Ⲁ and the other the small letter ⲁ, both in coral #FF7A5C, so they clearly look like a matching pair. One front card is caught mid-flip, lifted and turning, with two small curved motion lines beside it. Small sunny-yellow #FFC845 star sparkles burst between the two matching cards. A tiny cocoa-brown seashell rests near the bottom corner. Same size and weight as a single object illustration: bold, simple and readable at small size.
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

---

## Balloons game art (امسك البالونة), for ElevenLabs

Made with **ElevenLabs image generation** (Image & Video). Use the same
workflow as the other art: if the model you pick accepts a reference image,
attach `design/reference/nono-fofo-approved.webp` so the style matches the
brothers. Paste each prompt as it is.

| What | Save the original as | Then run |
|---|---|---|
| Village background | `design/reference/balloons/village.webp` | `tools/.venv/bin/python tools/games/process_balloons.py`; if the path sits higher or lower, change `backgroundMarks.feetY` in `app/assets/content/games/balloons.json` |
| Balloon (one ORANGE balloon; the script makes the 8 colors) | `design/reference/balloons/balloon.webp` | same script; copy the `balloonLetterSpot` and `balloonImages` lines it prints into `balloons.json` |
| Nono / Fofo balloon poses (later) | `Characters/Nono Balloons.webp`, `Characters/Fofo Balloons.webp` | `tools/.venv/bin/python tools/characters/process_poses.py` (add them to `SOURCES` first) |

Until a file is there the game draws that part in code, so the game works
without them. If ElevenLabs gives you a PNG or JPG, save it under the `.webp`
name above anyway: the script reads the file's content, not its extension.

### Village background (wide, landscape 16:9)

The brothers stand on the dirt path at the bottom, about 90% of the way
down, and balloons rise through the sky, so the sky has to be big and calm.

```
Wide landscape (16:9) background for a children's game, flat 2D vector cartoon style: thin warm-brown outlines, flat colors with soft shading, rounded friendly shapes, cheerful and simple. A sunny Egyptian countryside village seen from the front, side-on, like a stage. Top 50%: a big soft light-blue sky, a soft yellow sun in the top-left corner and a few round cream clouds; keep the top-center of the sky completely empty (a score card goes there). Middle: one long row of small traditional mud-brick village houses in soft pastel colors (sand, peach, pale blue, pale pink, pale yellow), flat roofs, some with a pile of straw or palm fronds on top, small arched wooden doors and little windows; one round white pigeon tower (برج حمام) with rows of little holes, a few date palms behind the houses. Below the houses: a strip of green fields with crop rows, then a narrow light-turquoise irrigation canal running across the whole picture. Bottom 15%: a wide, flat, empty warm-sand dirt path running across the whole width with a few small pebbles; keep it completely empty (two children will stand on it, one on the left and one on the right). Use this palette: deep teal #0F4C5C, mist blue #A8DADC, warm sand #EFE6D8, slate teal #4F7C82, cocoa brown #5B4B3A, sunny yellow #FFC845, coral #FF7A5C, leaf green #6CC24A, cream #FFFBF4. No people, no animals in the foreground, no balloons, no text, no letters, no logos, no watermark, no religious symbols.
```

### Balloon (generate once, in orange)

The game writes the letter in the cream circle and draws the string itself,
so the picture must have **no string** and an **empty** circle.

```
A single cute cartoon helium party balloon for a children's game, flat 2D vector style: thin warm-brown #5B4B3A outline, flat colors with soft shading, rounded friendly shape. Classic round balloon shape, slightly taller than wide, a small tied knot at the bottom center, front view, standing straight up. The balloon rubber is bright orange #FF9F43 with a slightly darker orange on one side and one big soft white shine highlight on the upper left. In the middle of the balloon there is a large EMPTY plain cream #FFFBF4 circle with a thin brown outline (about half the balloon width), slightly above the center; leave it completely empty, no letter, no pattern inside. NO string, nothing hanging below the knot. Whole balloon visible, centered, nothing else in the picture. Plain flat pure white background so it can be cut out. No text, no letters, no watermark.
```

### Balloon poses for Nono and Fofo (later)

Not needed to play: for now the game uses the existing poses and moves them
in code. One sheet per brother, two poses side by side, full body:

```
Using the attached reference for the exact look, clothes and colors: [NONO / FOFO], full body, two poses side by side on one sheet, both facing RIGHT. Pose 1 "jump" (left): jumping up with both feet off the ground, one arm stretched straight up with the hand closed in a fist as if grabbing a string, big excited smile. Pose 2 "hold" (right): standing, one hand raised above his head with the fist closed as if holding several balloon strings, the other hand on his hip, proud happy smile. No balloons and no strings (the game draws them). Same flat 2D style, thin warm-brown outlines. Plain solid white background, no shadow, no text.
```

---

## Write the letter art (اكتب الحرف), for ElevenLabs

Made with **ElevenLabs image generation** (Image & Video), like the balloons
art. If the model you pick accepts a reference image, attach
`design/reference/nono-fofo-approved.webp` so the style matches the
brothers. Paste each prompt as it is.

| What | Save the original as | Then run |
|---|---|---|
| Grandpa's study background | `design/reference/writing/study.webp` | `tools/.venv/bin/python tools/games/process_writing.py`, then paste the `"art"` line it prints into `app/assets/content/games/writing.json` |
| Chalkboard (empty) | `design/reference/writing/board.webp` | same script |
| Nono / Fofo board poses (later) | `Characters/Nono Board.webp`, `Characters/Fofo Board.webp` | `tools/.venv/bin/python tools/characters/process_poses.py` (add `chalk` and `sponge` to `SOURCES` first) |

Until a file is there the game draws that part in code, so it plays without
them. If ElevenLabs gives you a PNG or JPG, save it under the `.webp` name
above anyway: the script reads the file's content, not its extension. Until
the board poses exist, the hero uses his `write` pose and the other brother
his `encourage` pose.

### Grandpa's study (wide, landscape 16:9)

The board covers the middle of the picture and the brothers stand on the
floor at the left and right, so the middle must stay empty.

```
Wide landscape (16:9) background for a children's game, flat 2D vector cartoon style: thin warm-brown outlines, flat colors with soft shading, rounded friendly shapes, cheerful and simple. The inside of a cozy old Egyptian grandfather's study, seen from the front like a stage. Back wall in warm sand and cream plaster. On the left and right sides: tall wooden bookshelves full of old leather books in cocoa brown, teal and coral, a few rolled scrolls, a small brass lamp. Upper right: a wooden mashrabiya window with warm afternoon sunlight making soft patterned light on the wall. Lower left corner: a comfy old armchair with a knitted cushion. The floor is warm wood with a patterned rug in teal, coral and sunny yellow. Keep the whole CENTER of the picture (about 55% of the width, from 10% to 85% of the height) as a plain empty wall, because a big chalkboard will be placed there. Keep the floor in front of the left and right shelves empty, because two children will stand there. Use this palette: deep teal #0F4C5C, mist blue #A8DADC, warm sand #EFE6D8, slate teal #4F7C82, cocoa brown #5B4B3A, sunny yellow #FFC845, coral #FF7A5C, leaf green #6CC24A, cream #FFFBF4. No people, no chalkboard, no text, no letters, no logos, no watermark, no religious symbols.
```

### Chalkboard (generate once)

The game paints the green surface and the letter itself, so only the wooden
frame of this picture shows; keep the frame an even thickness all round.

```
A single cartoon school chalkboard for a children's game, flat 2D vector style: thin warm-brown #5B4B3A outline, flat colors with soft shading. Wide landscape rectangle, about 3:2, front view, standing straight. Rounded wooden frame of the same thickness on all four sides, in warm cocoa brown with light wood grain and small round pegs in the corners. The board surface is a soft deep chalkboard GREEN (#2F5D4E), completely EMPTY, with nothing written on it. Whole board visible, centered, nothing else in the picture. Plain flat pure white background so it can be cut out. No text, no letters, no chalk marks, no chalk ledge, no watermark.
```

### Board poses for Nono and Fofo (later)

Not needed to play. One sheet per brother, two poses side by side, full body:

```
Using the attached reference for the exact look, clothes and colors: [NONO / FOFO], full body, two poses side by side on one sheet. Pose 1 "chalk" (left), facing RIGHT: standing sideways, one arm raised forward at shoulder height holding a short white stick of chalk as if writing on a wall, focused happy face, tongue slightly out in concentration. Pose 2 "sponge" (right), facing LEFT: standing, one arm raised forward holding a yellow rectangular cleaning sponge as if wiping a wall, cheeky friendly smile. No chalkboard and no wall (the game draws them). Same flat 2D style, thin warm-brown outlines. Plain solid white background, no shadow, no text.
```

---

## Grandpa's Cards art (كروت جدو)

Same workflow as the writing art (Gemini or ElevenLabs; attach
`design/reference/nono-fofo-approved.webp` when the model accepts a
reference). Until a file is there the game draws that part in code, so it
plays without them.

| What | Save as | Then |
|---|---|---|
| Road card illustration | `app/assets/games/cards.png` | Nothing: the road shows it as soon as it's there (prompt 5 above) |
| Alexandria seaside background | `app/assets/games/cards_seaside.webp` | Set `"background": "assets/games/cards_seaside.webp"` under `"art"` in `app/assets/content/games/cards.json` |
| Card back | `app/assets/games/cards_back.png` | Set `"cardBack": "assets/games/cards_back.png"` under `"art"` in the same file |

Resize the background to about 1920 px wide before saving it (it's the
whole screen behind the table). If you'd rather I process them, drop the
originals in `design/reference/cards/` and ask.

### Alexandria by the sea (wide, landscape 16:9)

The cards cover most of the middle and the brothers stand on the sand at
the left and right, so the middle must stay calm and plain.

```
Wide landscape (16:9) background for a children's game, flat 2D vector cartoon style: thin warm-brown outlines, flat colors with soft shading, rounded friendly shapes, cheerful and simple. A sunny day on the Alexandria seafront in Egypt, seen from the beach like a stage. Top 35%: soft light-blue sky with two or three puffy clouds and a few white seagulls, a sunny-yellow sun in the upper right. Far away on the left, on the horizon, the small sandy-coloured Qaitbay citadel on its rocks; far away on the right, a few soft pastel buildings of the Corniche and a small blue-and-white fishing boat. Middle band: calm turquoise and mist-blue sea with gentle white foam lines. Bottom half: smooth warm golden sand with a soft wavy foam edge. In the bottom left corner a striped beach umbrella in coral and cream; in the bottom right corner a small bucket and spade and a starfish. Keep the whole CENTER of the picture (about 65% of the width, from 12% to 95% of the height) plain and calm (just sea and sand, no objects), because a grid of cards will be placed there. Keep the sand in front of the left and right edges empty, because two children will stand there. Use this palette: deep teal #0F4C5C, mist blue #A8DADC, warm sand #EFE6D8, slate teal #4F7C82, cocoa brown #5B4B3A, sunny yellow #FFC845, coral #FF7A5C, leaf green #6CC24A, cream #FFFBF4. No people, no cards, no text, no letters, no logos, no watermark, no religious symbols.
```

### Card back (portrait 3:4, generate once)

Every face-down card shows this picture, from about 40 px to 170 px wide,
so it has to stay clear and simple when small.

```
The back of a single playing card for a children's memory game, flat 2D vector style, front view, filling the whole picture edge to edge, portrait 3:4. Deep teal #0F4C5C background with a thin mist-blue #A8DADC rounded border inset a little from the edge, and a soft, subtle diamond lattice pattern in a slightly lighter teal. In the centre, a simple round medallion in cream #FFFBF4 with a small cocoa-brown #5B4B3A seashell inside it and a tiny sunny-yellow #FFC845 star above the shell. Symmetrical, clean, no shadows outside the card, square corners (the game rounds them). No text, no letters, no numbers, no logos, no watermark.
```
