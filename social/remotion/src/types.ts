// The shape of social/videos/<id>/video.json. See social/README.md.

export type ColorName = string; // any key of AppColors (app_colors.dart), e.g. "sunYellow"

export type PoseInfo = {file: string | null; width: number; height: number; head: [number, number]}; // file null = image not made yet (placeholder)

export type Line = {
  id: string; // voice file name without extension: voice/<id>.mp3
  speaker: string; // 'nono' | 'fofo' | a guest from social/assets/manifest.json (e.g. 'ramses')
  say: string; // ElevenLabs v3 text with [tags], pasted as-is
  ar: string; // on-screen Arabic caption (no tags)
  en: string; // English subtitle
  estimate: number; // seconds, used until the voice file exists
  words?: number[]; // optional: start time (s, from voice start) of each Arabic word
};

export type CharacterSpec = {
  who: string; // 'nono' | 'fofo' | a guest (e.g. 'ramses')
  pose: string;
  at?: 'center' | 'left' | 'right';
  enter?: 'left' | 'right' | 'bottom' | 'pop' | 'none';
  flip?: boolean;
  swaps?: {at: number; pose: string}[]; // seconds from scene start
  size?: number; // height multiplier (1 = standing height)
  x?: number; // custom x of the feet center (overrides `at`)
  delay?: number; // seconds from scene start before he enters
  // slide sideways: offset in px from his spot, reached at `at` (scene seconds) over `dur`;
  // `flip` sets which way he faces from that moment
  moves?: {at: number; to: number; dur?: number; flip?: boolean}[];
};

export type Keyword = {
  ar: string;
  en: string;
  icon?: string; // key of ICONS (src/icons.ts)
  side?: 'left' | 'center' | 'right'; // where the card sits (default: center for one card, alternating for more)
  coptic?: string; // the word spelled in Coptic letters (Avva keys), shown in gold above the Arabic
  at: number; // seconds from voice start
};

// Motion-graphics props (src/components/Props.tsx). Times are seconds from the
// voice start (like keywords); negative = during the scene lead-in.
export type PropSpec =
  | {kind: 'book'; x?: number; y?: number; size?: number; openAt?: number; burstAt?: number; letterInAt?: number; letterFrom?: [number, number]; letter?: string; found?: string} // letter: Avva key that flies in (default A); found: one already on the page
  | {kind: 'egypt'; at?: number}
  | {
      kind: 'letter';
      capital: string; // Avva key, e.g. "A"
      small: string; // Avva key, e.g. "a"
      ar: string;
      en: string;
      sound?: string; // Arabic letter for its sound, shown on pulseAt (e.g. "ا")
      soundEn?: string; // e.g. "a"
      start?: 'float' | 'pyramid' | 'card';
      at?: number; // float: drops in
      pyramidAt?: number; // turns into a pyramid (Nono's guess)
      letterAt?: number; // pyramid melts back into the letter
      cardAt?: number; // grows into the letter card
      pulseAt?: number; // the small letter "says" its sound
      soundAt?: number; // the sound chip shows up (defaults to pulseAt)
      outAt?: number; // shrinks away (flies into the book)
    }
  | {kind: 'slots'; total: number; filled: number; to?: number; stretchAt?: number; labels?: {at: number; ar: string; en: string}[]}
  | {kind: 'speed'; at?: number; until?: number}
  | {kind: 'ball'; at: number; x: number; y: number; size?: number} // football bounces in from the right
  | {kind: 'rain'; at?: number; count?: number} // gold Coptic letters fall and bounce off the brothers' heads
  | {kind: 'shake'; at: number}
  | {kind: 'arrow'; at: number; x: number; y: number; dir: 'left' | 'right'}
  // a Coptic letter on little legs running along a path (keyframes: reach x,y at `at`); hop = arcs between points
  | {kind: 'runner'; k: string; size?: number; path: {at: number; x: number; y: number; hop?: number}[]}
  // little living statues (cat, jar, bust, ankh) tiptoeing and searching; from `chaseAt` they run off to `chase`
  | {kind: 'statues'; at?: number; y?: number; chaseAt?: number; chase?: 'left' | 'right'; layer?: 'back' | 'front'}
  | {kind: 'dizzy'; at: number; x: number; y: number; until?: number} // stars spinning around a head after a bonk
  | {kind: 'pant'; at: number; x: number; y: number; until?: number; dir?: 'left' | 'right'} // breath puffs + sweat drops (out of breath)
  | {kind: 'compare'; at: number; k: string; latin: string; y?: number} // Coptic letter ≈ Latin letter
  | {kind: 'confetti'; at: number; count?: number};

export type SceneSpec = {
  id: string;
  bg: ColorName;
  bg2?: ColorName; // ray / pattern color (defaults to a lighter tint)
  // rays/dots/letters, or a themed moving scene (components/Scenery.tsx)
  pattern?: 'rays' | 'dots' | 'letters' | 'cairo' | 'field' | 'doodles' | 'icons' | 'study' | 'waves' | 'desert' | 'board' | 'grid' | 'track' | 'trail';
  icons?: string[]; // for pattern "icons": keys of ICONS that float and light up
  characters?: CharacterSpec[];
  line?: Line & {voice?: string | null};
  keywords?: Keyword[];
  sfx?: {id: string; at: number; volume?: number}[]; // extra sounds, seconds from scene start
  hold?: number; // extra seconds after the line
  props?: PropSpec[];
  backdrop?: string; // id of a social image (social/assets/manifest.json "images") drawn behind everything, with parallax
  // Camera moves (scene seconds): the world (characters + props) pans/zooms,
  // the background follows with parallax. x/y = camera offset in px.
  camera?: {at: number; x?: number; y?: number; zoom?: number; rot?: number; dur?: number}[];
  patternAt?: number; // the themed background appears at this time (seconds from voice start)
  before?: {pattern: string; icons?: string[]}; // background shown until patternAt
  transition?: 'wipe' | 'whip' | 'cut'; // how this scene comes in (default: circle wipe; cut = same shot continues)
};

export type VideoSpec = {
  id: string; // folder name, filled in by sync
  title: string;
  music?: {track: string; volume?: number};
  pace?: {lead?: number; tail?: number}; // seconds around each line (defaults in theme.ts)
  scenes: SceneSpec[];
  endCard?: {ar: string; en: string; voice?: string | null; duration?: number}; // voice: file id in voice/ (both brothers together)
};

export type Timing = {
  fps: number;
  scenes: {from: number; duration: number; voiceFrom: number; voiceFrames: number}[];
  endFrom: number;
  total: number;
};
