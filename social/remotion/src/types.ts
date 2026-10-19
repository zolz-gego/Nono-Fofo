// The shape of social/videos/<id>/video.json. See social/README.md.

export type ColorName = string; // any key of AppColors (app_colors.dart), e.g. "sunYellow"

export type PoseInfo = {file: string; width: number; height: number; head: [number, number]};

export type Line = {
  id: string; // voice file name without extension: voice/<id>.mp3
  speaker: 'nono' | 'fofo';
  say: string; // ElevenLabs v3 text with [tags], pasted as-is
  ar: string; // on-screen Arabic caption (no tags)
  en: string; // English subtitle
  estimate: number; // seconds, used until the voice file exists
  words?: number[]; // optional: start time (s, from voice start) of each Arabic word
};

export type CharacterSpec = {
  who: 'nono' | 'fofo';
  pose: string;
  at?: 'center' | 'left' | 'right';
  enter?: 'left' | 'right' | 'bottom' | 'pop' | 'none';
  flip?: boolean;
  swaps?: {at: number; pose: string}[]; // seconds from scene start
};

export type Keyword = {
  ar: string;
  en: string;
  icon?: string; // key of ICONS (src/icons.ts)
  at: number; // seconds from voice start
};

export type SceneSpec = {
  id: string;
  bg: ColorName;
  bg2?: ColorName; // ray / pattern color (defaults to a lighter tint)
  pattern?: 'rays' | 'dots' | 'letters';
  characters?: CharacterSpec[];
  line?: Line & {voice?: string | null};
  keywords?: Keyword[];
  sfx?: {id: string; at: number; volume?: number}[]; // extra sounds, seconds from scene start
  hold?: number; // extra seconds after the line
};

export type VideoSpec = {
  id: string; // folder name, filled in by sync
  title: string;
  music?: {track: string; volume?: number};
  scenes: SceneSpec[];
  endCard?: {ar: string; en: string};
};

export type Timing = {
  fps: number;
  scenes: {from: number; duration: number; voiceFrom: number; voiceFrames: number}[];
  endFrom: number;
  total: number;
};
