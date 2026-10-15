# Nono & Fofo: image-tool prompts

For Gemini (Nano Banana / Imagen), ChatGPT images, Midjourney and similar tools.

How to use:
1. Run **Prompt 1** until you love the result.
2. Upload that image as a reference with every later prompt, so the brothers stay on-model.
3. Use the **pose prompts** one at a time, always attaching the approved sheet.

---

## Prompt 1: Character sheet (both brothers)

```
Character design sheet for a children's educational app. Two Egyptian Coptic brothers, cute flat 2D vector cartoon style, clean bold dark outlines, simple flat colors with minimal soft shading, big expressive eyes, rounded friendly shapes, chibi proportions (big heads, small bodies). Plain white background, front view, full body, both standing side by side on the same ground line so their height difference is clear.

LEFT: NONO, 9-year-old older brother. Taller and slim. Cute fluffy curly dark-brown hair, soft bouncy curls on top. Warm light-brown Egyptian skin, big shiny dark-brown eyes, rosy cheeks, a big happy open smile. Full of energy, standing on his tiptoes as if he is about to run. Wears a deep teal T-shirt (#0F4C5C) with a small sunny-yellow lightning bolt on the chest, brown shorts (#5B4B3A), white socks and coral-red sneakers (#FF6B5B).

RIGHT: FOFO, 6-year-old younger brother. Clearly shorter than Nono, with a normal slim little-kid build (not chubby, not fat). Cute curly light-brown hair (warm caramel color), soft round curls, lighter than Nono's hair. Egyptian facial features: same warm olive-tan skin as his brother, big round warm-brown eyes, natural Egyptian nose, a calm sweet smile with a missing front tooth. No glasses. He looks calm and curious, with one finger on his chin as if thinking. Wears a seafoam-blue T-shirt (#A8DADC) with a small leaf-green pocket, blue-grey shorts (#4F7C82), white socks and sunny-yellow sneakers (#FFC93C).

Both are clearly Egyptian (Middle Eastern) children and look like real brothers from Cairo, with the same skin tone and family resemblance. Not East Asian, not anime style. Friendly and lovable, aimed at children aged 4 to 12. Casual clothes only, no religious symbols, no text, no logos. Consistent style like a modern Pixar-inspired 2D storybook, but flat vector.
```

## Prompt 2: Turnaround (one brother at a time)

```
Using the attached character sheet as the exact reference, create a turnaround sheet of [NONO / FOFO]: front view, three-quarter view, side view and back view, full body, same proportions, same hair, same clothes and colors. Flat 2D vector cartoon, bold dark outlines, plain white background, no text.
```

## Prompt 3: Expressions

```
Using the attached character sheet as the exact reference, create an expression sheet of [NONO / FOFO]: 9 head close-ups in a 3x3 grid. Happy, laughing, surprised, thinking, oops (embarrassed), sad, determined, sleepy, excited. Same face, hair and style. Flat 2D vector cartoon, bold outlines, plain white background, no text.
```

## Pose prompts

Start every pose prompt with:

```
Using the attached character sheet as the exact reference, draw [NONO / FOFO] in the same flat 2D vector cartoon style, same proportions, hair, clothes and colors, full body, plain white background, no text, centered with space around him:
```

Then add one of these:

| Pose | Nono (energetic, rushes in) | Fofo (calm, thinks first) |
|---|---|---|
| Idle | bouncing on his tiptoes, arms swinging, big grin | finger on chin, looking up thoughtfully, small smile |
| Cheer (correct answer) | both fists in the air, eyes closed with joy, mouth wide open | both arms up, happy closed eyes, sweet smile |
| Oops (wrong answer) | scratching the back of his head, embarrassed wobbly smile, small sweat drop | head tilted, puzzled look, small question mark above his head |
| Hint | pointing quickly to the side with one arm stretched out, excited | raising one finger, a glowing yellow lightbulb above his head |
| Celebrate (lesson done) | jumping high in a star jump, confetti and yellow stars around him | small happy jump, both arms up, confetti and stars |
| Encourage (try again) | big thumbs up, warm smile, other hand on his hip | gentle thumbs up, kind encouraging smile |
| Run | running fast with motion lines and a dust cloud behind him | jogging carefully, small motion lines |
| Hello (welcome) | waving one hand high, big friendly grin | waving shyly, sweet smile |
| Write | holding a big yellow pencil and a small chalkboard, tongue sticking out, concentrating | holding a pencil and a small chalkboard, writing slowly and carefully |
| Read | holding an open storybook, mouth in an "oh" shape, amazed | holding an open storybook, calm smile, reading closely |
| Sleep | sitting on the floor, head tilted, eyes closed, little drool, "Zzz" | sitting on the floor curled up, eyes closed, peaceful, "Zzz" |
| Surprised | jumping back, eyes wide, mouth open "O", two exclamation marks | hands on his cheeks, eyes wide, mouth open "O" |

## Tips

- **Getting a clean cutout:** most tools can't make a transparent background. Keep "plain white background", then remove it with remove.bg or the background-removal tool in Canva or Photoshop.
- **If Fofo comes out looking East Asian or chubby:** add "Egyptian boy, slim build, not chubby, not anime, light-brown curly hair" at the end and regenerate. Attaching a reference photo of an Egyptian child also helps.
- **Keeping the style the same:** if a brother changes between images, say "keep exactly the same face, hair and clothes as the reference" and regenerate.
- **Using the art in the app:** for animation in Flutter, the final art should be vector (SVG). Send me the best images and I'll redraw them as SVGs that match.
