import {loadFont} from '@remotion/fonts';
import {staticFile} from 'remotion';
import {colors} from './generated/data';

// Colors always come from the app's AppColors (copied by sync-assets).
export const C = colors as unknown as Record<string, string>;
export const color = (name: string) => C[name] ?? name;

// Same fonts as the app: Baloo Bhaijaan 2 (Arabic), Baloo 2 (English),
// Avva Shenouda (Coptic, typed with Latin keys).
export const FONT_AR = 'BalooBhaijaan2';
export const FONT_EN = 'Baloo2';
export const FONT_COPTIC = 'AvvaShenouda';

loadFont({family: FONT_AR, url: staticFile('app/fonts/BalooBhaijaan2.ttf'), weight: '400 800'});
loadFont({family: FONT_EN, url: staticFile('app/fonts/Baloo2.ttf'), weight: '400 800'});
loadFont({family: FONT_COPTIC, url: staticFile('app/fonts/Avva_Shenouda.ttf')});

export const W = 1080;
export const H = 1920;
export const FPS = 30;

// Seconds around each line and between scenes.
export const LEAD = 0.35; // scene opens, characters land, then the voice starts
export const TAIL = 0.45; // after the voice, before the next scene
export const MIN_SCENE = 1.6;
export const WIPE = 10; // frames the next scene takes to wipe in
export const END_CARD = 2.6;

// Safe areas for TikTok / Reels UI (top bar, right buttons, bottom caption).
export const SAFE = {top: 150, bottom: 1560, left: 70, right: 930};
