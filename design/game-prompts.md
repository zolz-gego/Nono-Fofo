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
| دوّر في الدير / Search the Monastery | `monastery.png` |
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

### 6. Search the Monastery: `monastery.png`

Paste the style block first, like the other cards. Save the result as
`design/reference/monastery/icon.webp`; `tools/games/process_monastery.py`
cuts it out and puts it on the same beige square as the other cards
(`app/assets/games/monastery.png`).

```
A round terracotta clay water jar (an Egyptian zeer) with a narrow neck and a deep-teal #0F4C5C zigzag band, standing on a small cocoa-brown wooden stand, centered. A big Coptic letter Ⲃ in cocoa brown #5B4B3A peeks out from behind the jar on one side, only half of it showing, as if it is hiding. A big magnifying glass with a chunky sunny-yellow #FFC845 handle and a mist-blue #A8DADC lens floats in front at an angle, its lens over the peeking Ⲃ so that part of the letter looks bigger through the glass. A few small sunny-yellow star sparkles around the lens. Playful hide-and-seek feeling. Same size and weight as a single object illustration: bold, simple and readable at small size.
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

Road card and background are done (2026-10-17): the originals are in
`design/reference/cards/` (`icon.webp`, `seaside.webp`); to swap one, replace
it there and run `tools/.venv/bin/python tools/games/process_cards.py` (it
puts the icon on the beige square and sizes the background).

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

---

## Search the Monastery art (دوّر في الدير)

The room is built in layers: an **empty room** picture, then **cut-out
objects** placed on top of it. The letters hide between the two, so only
the bit that sticks out from behind an object shows. Until a file is there
the game draws that part in code, so it plays without them. Attach
`design/reference/nono-fofo-approved.webp` when the model accepts a
reference, so the style matches.

| What | Save as | Then |
|---|---|---|
| Road card illustration | `design/reference/monastery/icon.png` | Claude puts it on the beige square as `app/assets/games/monastery.png` (prompt 6 above) |
| Empty room, wide (16:9), for tablets and computers | `design/reference/monastery/room.png` | Claude sizes it and sets the wide scene's `background` in `app/assets/content/games/monastery.json` |
| Empty room, tall (3:5), for phones | `design/reference/monastery/room_tall.png` | Claude sizes it and sets the tall scene's `background` in the same file |
| The 12 objects (white background) | `design/reference/monastery/<id>.png`, e.g. `chair.png` | Claude cuts them out, sets each object's `image`, and moves the hiding spots to fit the new shapes |

Phones never scroll: they get their own **tall room**, with the same objects
arranged differently. So the objects are made once and used in both rooms;
only the empty room is needed twice.

Room and object art is done (2026-10-17): the originals are in
`design/reference/monastery/`. To swap one, replace it there (same name) and
run, from the repo root:

1. `tools/.venv/bin/python tools/games/process_monastery.py`: cuts the
   objects out of their white background (holes too) and sizes everything
   into `app/assets/games/monastery/`. It prints each object's width/height;
   keep the object's `rect` in the JSON the same shape.
2. `tools/.venv/bin/python tools/games/monastery_spots.py`: works out the
   hiding spots from the outlines (letters about half hidden) and writes a
   preview with every spot circled to `design/reference/monastery/preview_*.png`.

Road card (`icon.webp`, the chair) and level card (`level_card.webp`) are
done too (2026-10-17); `process_monastery.py` handles both.

### Level tile (one picture for every level)

Every tile in the "how many letters?" picker shows this same picture, with
the number written under it ("5 حروف", "6 حروف"…). Paste the **style block**
first, then this. Not used: the level card (`level_card.webp`) was chosen instead. Until it's there the tiles draw a magnifying glass over a few letters.

```
A single small wooden chair with a round spindle back, in warm cocoa-brown wood, slightly turned, centered. Two Coptic letters in cocoa brown #5B4B3A hide behind it, each only partly showing: a capital Ⲁ peeking out above the chair's back and a small ⲅ peeking out between the chair's legs. A big magnifying glass with a chunky sunny-yellow #FFC845 handle and a mist-blue #A8DADC lens leans in from one side, its lens over the peeking Ⲁ. A couple of small sunny-yellow star sparkles. No numbers. Very simple, bold and readable at small size, because it is shown only about 100 pixels wide on a button.
```

---

## Snakes & Ladders art (السلم والتعبان)

The level's challenge, by the Pyramids. The board's snakes and ladders sit
on **fixed squares** (in `app/assets/content/games/snakes_ladders.json`),
and image models can't put them on exact squares. So the board itself (the
8×8 squares, their numbers, and where each snake and ladder starts and
ends) stays drawn in code, and the art comes in parts that Claude places
and stretches onto those squares. Until a file is there the game draws that
part in code, so it plays without them. Attach
`design/reference/nono-fofo-approved.webp` when the model accepts a
reference, so the style matches.

| What | Save as | Then |
|---|---|---|
| Pyramids background, wide (16:9), for tablets and computers | `design/reference/snakes/pyramids.png` | Claude sizes it and uses it behind the board instead of the painted sky |
| Pyramids background, tall (3:5), for phones | `design/reference/snakes/pyramids_tall.png` | Same, for phones |
| One wooden ladder (white background) | `design/reference/snakes/ladder.png` | Claude cuts it out and stretches it between each ladder's squares |
| Five snakes (white background), one per colour | `design/reference/snakes/snake_<colour>.png` | Claude cuts them out and lays each along a snake's head and tail squares |

Done (2026-10-17): the wide background is in `design/reference/snakes/`
and used behind the board. A ladder and a green snake were tried as pictures
too, but the drawn snakes and ladders were kept (the originals are still in
that folder). To swap the background (or add `pyramids_tall.webp`), put it
there and run, from the repo root:
`tools/.venv/bin/python tools/games/process_snakes.py`.

Paste the style block first for each one.

### Pyramids background (wide, landscape 16:9)

```
A wide, calm desert scene at Giza for the background of a children's board game. The three Pyramids of Giza stand on the left half, in warm sand colours (light side #E9C27E, shaded side #C99A55), the biggest in front. A clear light-blue sky that fades to pale cream near the horizon, a soft round sun in the top right. Low rolling sand dunes across the bottom third, a few small desert plants. The middle and right of the picture stay simple and quiet (a board will sit on top of it), with no people, animals, text or letters. Flat colours with soft shading, thin warm-brown outlines.
```

For the tall one, use the same prompt but say *tall portrait picture (3:5)*,
with the Pyramids small in the upper part and plain dunes filling the lower
two thirds.

### Ladder (generate once)

```
One straight wooden ladder lying flat, seen from straight above, pointing straight up, on a plain white background. Two light-brown wooden rails (#A0704A with darker #6E4A2F edges) and seven evenly spaced rungs (#C8935E). Chunky, simple and friendly, like a toy, with a thin warm-brown outline. Nothing else in the picture.
```

### Snakes (one per colour)

Generate one per colour: green #6CC24A, coral #FF7A5C, lilac #B57EDC,
mint #3FBFA0 and orange #FF9F43.

```
One friendly cartoon snake for a children's board game, lying in a long gentle S-curve from the top of the picture to the bottom, seen from above, on a plain white background. The head is at the top: round, with big friendly eyes, a small smile and a little red forked tongue. The body is <colour>, with a lighter round-spot pattern down its back, and it gets thinner towards the tail at the bottom. Cute, not scary. Thin warm-brown outline, flat colours with soft shading. Nothing else in the picture.
```

## Nono & Fofo Adventure art (مغامرة نونو وفوفو)

The Adventure is a side-scroller in three levels (the Nile bank, the desert
and Pyramids, Alexandria at night). The backgrounds, ground, blocks and
enemies are in (originals in `design/reference/adventure/`; to swap one,
replace it there and run `tools/.venv/bin/python tools/games/process_adventure.py`).
The page, book, gate and flags are still drawn in code
(`app/lib/features/games/adventure/game/adventure_art.dart`). The level
maps stay in `app/assets/content/games/adventure.json`, so the art never
changes where things are.

Paste the style block first for each one.

### Backgrounds (one per level, very wide 3:1, made to repeat sideways)

```
A very wide side-view background for a children's 2D platform game, made so the left and right edges join up when repeated. <PLACE>. Seen from the side like a stage set, with the far scenery in the upper two thirds and a plain, quiet strip at the bottom (the ground tiles sit on top of it). No people, animals, text or letters. Flat colours with soft shading, thin warm-brown outlines.
```

Places:
- *Nile bank*: light-blue sky, a soft sun, green fields and palm trees on the far bank, the Nile in the middle.
- *Desert and Pyramids*: warm orange-to-cream sky, the three Pyramids of Giza far away, rolling sand dunes.
- *Alexandria at night*: deep navy sky with stars and a crescent moon, the sea, the Qaitbay citadel with a lighthouse glow, city buildings with warm lit windows.

### Ground and blocks (square tiles, 1:1, one picture each)

```
One square game tile for a children's 2D platform game, seen straight from the side, filling the whole picture edge to edge so it repeats seamlessly sideways: <TILE>. Flat colours with soft shading, thin warm-brown outline. Nothing else in the picture.
```

Tiles: *grass-topped earth* (Nile), *sand-topped earth* (desert), *paved stone* (Alexandria),
*stone block*, *red brick block*, *golden "?" block*, *used plain brown block*.

### Enemies (side view, facing left, plain white background)

```
One friendly-but-grumpy cartoon <ENEMY> walking to the left, seen from the side, for a children's platform game. Cute, not scary, with a cheeky frown. Plain white background, thin warm-brown outline, flat colours with soft shading. Nothing else in the picture.
```

Enemies: *white duck with an orange beak* (Nile), *brown desert scorpion* (desert),
*red crab* (Alexandria), *white seagull with grey wings, flying* (Alexandria).

Alexandria's seagulls now fly over the path and drop shells, so a flying
pose would look better than the walking one (save it as `seagull.webp`):

```
One friendly-but-grumpy cartoon white seagull with grey wings, flying to the left with its wings spread wide, seen from the side, for a children's platform game. Cute, not scary. Plain white background, thin warm-brown outline, flat colours with soft shading. Nothing else in the picture.
```

### Items

- *Grandpa's glowing page*: an old cream paper page with golden lines of writing, glowing softly.
- *Grandpa's book*: Grandpa's very old book, open, on a small wooden stand, its pages shining like gold.
- *The letters gate*: a tall sandstone gate with a rounded wooden door and five round empty slots above it.
- *Checkpoint flag*: a wooden pole with a green triangular flag.

### Side-view poses for Nono and Fofo (later)

The game uses the existing *run*, *idle*, *cheer* (jumping), *surprised*
(hurt) and *celebrate* poses for now. Proper side-view *run* (3–4 frames)
and *jump* poses would make the running look smoother.

---

## Magic basket art (السلة السحرية), Level 2, for ElevenLabs

The game reuses the balloons village background. The pictures below are in
the game (generated 2026-10-22); to swap one, save the new original under the
same name and run the script. Until a file is there the game draws that part
in code. Attach `design/reference/nono-fofo-approved.webp` when the model
accepts a reference image.

| What | Save the original as | Then run |
|---|---|---|
| Road card | `design/reference/magic_basket/icon.webp` | `tools/.venv/bin/python tools/games/process_magic_basket.py` |
| Apple tree (cut-out) | `design/reference/magic_basket/tree.webp` | same script; if the branch moves, change `treeMarks` in `app/assets/content/games/magic_basket.json` |
| Apple (empty label) | `design/reference/magic_basket/apple.webp` | same script; copy the `appleLetterSpot` line it prints into `magic_basket.json` |
| Basket | `design/reference/magic_basket/basket.webp` | same script; copy the `basketOpening` line it prints into `magic_basket.json` |
| Nono / Fofo poses (sit, toss, carry) | `Characters/Nono Basket.webp`, `Characters/Fofo Basket.webp` | `tools/.venv/bin/python tools/characters/process_poses.py` (seat and hand points are in its `SEAT` / `HAND` tables) |

### Road card: `magicBasket.png`

Paste the style block first, like the other cards.

```
A round woven wicker basket in warm tan with a thick rim, centered and slightly tilted toward the viewer, half full of shiny red apples. Two more red apples fall into it from above with small curved motion lines, each with a small cream circle on it showing a big letter: one shows the Arabic letter ب and the other the Latin letter b. A green apple leaf twirls beside them and a few small sunny-yellow #FFC845 star sparkles burst around the basket, as if it is magic. Same size and weight as a single object illustration: bold, simple and readable at small size.
```

### Apple tree (wide, cut-out)

The tree fills the top of the screen; one brother sits on a branch at the
side and the apples fall from under the leaves.

```
A big wide cartoon apple tree for a children's game, flat 2D vector style: thin warm-brown #5B4B3A outlines, flat colors with soft shading, rounded friendly shapes. Very wide, low crown made of round leafy clumps in three greens (leaf green #6CC24A, mid green #5E9E45, dark green #4A8238), much wider than tall, spreading across the whole picture. A short thick brown trunk in the center with two big limbs going up into the crown, and its roots spreading at the bottom. One long sturdy branch sticks out on the LEFT side under the crown, empty, strong enough for a child to sit on. About ten small red apples hidden among the leaves. Keep the area under the crown empty. Whole tree visible, front view, nothing else in the picture. Plain flat pure white background so it can be cut out. No people, no text, no letters, no watermark.
```

### Apple (generate once)

The game writes the sound in the cream circle, so it must stay empty.

```
A single cute cartoon red apple for a children's game, flat 2D vector style: thin warm-brown #5B4B3A outline, flat colors with soft shading, rounded friendly shape. Shiny bright red apple, a little darker red on one side, one soft white shine highlight on the upper left, a short brown stem with one green leaf on top. In the middle of the apple a large EMPTY plain cream #FFFBF4 circle with a thin brown outline (about half the apple width); leave it completely empty. Front view, centered, nothing else in the picture. Plain flat pure white background so it can be cut out. No text, no letters, no watermark.
```

### Basket

```
A cartoon woven wicker basket for a children's game, flat 2D vector style: thin warm-brown #5B4B3A outline, flat colors with soft shading. Wide and shallow, wider at the top than at the bottom, warm tan weave with darker brown lines, a thick light rim, no handle. Front view, straight, empty, seen slightly from above so the inside of the rim shows. Centered, nothing else in the picture. Plain flat pure white background so it can be cut out. No text, no watermark.
```

### Basket poses for Nono and Fofo

```
Using the attached reference for the exact look, clothes and colors: [NONO / FOFO], full body, three poses side by side on one sheet, all facing RIGHT. Pose 1 "sit" (left): sitting on an invisible branch with legs dangling, hands resting on his knees, happy smile. Pose 2 "toss" (middle): sitting the same way, one arm swinging down and forward as if dropping an apple, playful grin. Pose 3 "carry" (right): standing, holding an invisible wide basket in front of his tummy with both hands, arms a little forward, ready and excited. No basket, no apples, no branch (the game draws them). Same flat 2D style, thin warm-brown outlines. Plain solid white background, no shadow, no text.
```
