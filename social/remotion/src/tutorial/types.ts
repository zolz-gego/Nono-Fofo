// The shape of social/tutorials/<id>/tutorial.json (+ its recording). See the tutorial-video skill.
import type {Line} from '../types';

export type TLine = Omit<Line, 'speaker'> & {voice?: string | null}; // voice: set by sync (null until recorded)

export type TStep = {
  id: string;
  do: 'show' | 'tap' | 'type' | 'scroll' | 'wait' | 'play';
  find?: string; // regex on the accessibility node's label + text (recorder)
  text?: string; // type: what to type
  fast?: boolean; // setup recap: played sped up with a light highlight, no freeze
  line?: TLine; // narrated: freeze on the step while this plays (fast: plays over the sped-up run)
  lineAfter?: TLine; // play: plays over the live gameplay after the last narrated catch
  catches?: number | {ok?: boolean; line?: TLine}[]; // play: the catches to show; ok:false = a wrong one; line = narrated
  finish?: {line?: TLine}; // play: finish the round off camera, then jump cut to the result card
  zoom?: number; // override the zoom on this step
  [k: string]: unknown; // recorder options (game, letter, near, settle…)
};

export type TutorialSpec = {
  id: string;
  game?: string;
  site: string;
  intro?: string; // release intro override, "none" for no intro
  music?: {track: string; volume?: number};
  fastSpeed?: number;
  title: {ar: string; en: string; line?: TLine};
  steps: TStep[];
  end: {ar: string; en: string; link?: string; line?: TLine}; // link: shown as a pill (leave out while the address isn't final)
  recording: Recording | null;
};

export type Rect = [number, number, number, number]; // CSS px on the phone (390×844)

export type RecStep = {
  id: string;
  do: string;
  t0: number;
  t: number;
  t1: number;
  rect?: Rect | null;
  point?: [number, number];
  keys?: number[];
  taps?: {t: number; point: [number, number]; r: number; speed: number; ok?: boolean; key?: string}[];
  shownEnd?: number; // play: when the shown part ended (the rest of the round is off camera)
  finish?: {t: number; rect: Rect} | null; // play: the result card
};

export type Recording = {site?: string; recorded?: string; viewport: {width: number; height: number}; dpr: number; end: number; steps: RecStep[]; frames: {t: number; file: string}[]};

// ------------------------------------------------------------ plan (computed in calculateMetadata)

export type Seg = {from: number; frames: number; rt0: number; rt1: number}; // recording time rt0→rt1 over `frames` (rt0 = rt1: freeze)

export type Mark = {
  kind: 'tap' | 'show' | 'type' | 'catch';
  from: number; // highlight starts (frame)
  at: number; // the tap (frame)
  until: number; // highlight ends (frame)
  rect: Rect;
  round: boolean; // circle-ish (fish) instead of a rounded box
  zoom: number;
  tRec: number; // recording time of the tap (moving targets are at `rect` then)
  speed: number; // CSS px / s the target moves right (fish), 0 = still
  finger: boolean;
  big: boolean; // narrated step: full zoom, blur, whoosh + shimmer
};

export type Cue = {from: number; frames: number; line: TLine; captions: boolean};

export type Plan = {
  fps: number;
  intro: number; // intro frames before the story
  title: number; // title card frames (story starts with it)
  screenEnd: number; // story frame where the end card starts
  total: number; // story frames incl. end card (without intro)
  segs: Seg[];
  marks: Mark[];
  cues: Cue[];
  sfx: {at: number; id: string; volume: number}[];
  pops: {at: number; kind: 'ok' | 'wrong' | 'stars'}[]; // stickers over the phone
};
