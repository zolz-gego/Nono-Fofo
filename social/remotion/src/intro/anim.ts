// Timing / easing helpers for the logo intro. Everything works in
// seconds (t = frame / fps) so it lines up with cues.json.
import cuesJson from './cues.json';

export const cues = cuesJson;

export const clamp = (x: number, a = 0, b = 1) => Math.min(b, Math.max(a, x));
export const lerp = (a: number, b: number, p: number) => a + (b - a) * p;
export const prog = (t: number, a: number, b: number) => clamp((t - a) / (b - a));

export const ease = {
  outCubic: (p: number) => 1 - (1 - p) ** 3,
  inCubic: (p: number) => p ** 3,
  inOutCubic: (p: number) => (p < 0.5 ? 4 * p ** 3 : 1 - (-2 * p + 2) ** 3 / 2),
  inOutQuad: (p: number) => (p < 0.5 ? 2 * p * p : 1 - (-2 * p + 2) ** 2 / 2),
  outExpo: (p: number) => (p >= 1 ? 1 : 1 - 2 ** (-10 * p)),
};

// Decaying 1 -> 0 kick that starts at t0 (flashes).
export const kick = (t: number, t0: number, decay = 0.25) => {
  const x = t - t0;
  return x < 0 ? 0 : Math.exp(-x / (decay / 3));
};

// Stateless hash in [0, 1).
export const rnd = (seed: number) => {
  const s = Math.sin(seed * 12.9898 + 78.233) * 43758.5453;
  return s - Math.floor(s);
};

// Coptic letters typed with Latin keys in the Avva Shenouda font.
export const COPTIC = 'abgdezqiklmnxoprctufy'.split('');
