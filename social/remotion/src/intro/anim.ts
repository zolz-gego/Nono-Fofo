// Timing / easing / noise helpers for the logo intro. Everything works in
// seconds (t = frame / fps) so it lines up with cues.json.
import cuesJson from './cues.json';

export const cues = cuesJson;
export type Stage = (typeof cues.stages)[number];

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

// Seeded PRNG (mulberry32) so every render tab samples the same particles.
export const rng = (seed: number) => {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

// Stateless hash in [0, 1).
export const rnd = (seed: number) => {
  const s = Math.sin(seed * 12.9898 + 78.233) * 43758.5453;
  return s - Math.floor(s);
};

// Smooth pseudo-flow: a sum of sines in space and time. Cheap, stateless and
// swirly enough to read as a flock.
export const flow = (x: number, y: number, t: number, seed: number): [number, number] => {
  const a = Math.sin(x * 2.1 + t * 0.9 + seed) + Math.sin(y * 3.3 - t * 1.3 + seed * 1.7) * 0.6 + Math.sin((x + y) * 1.7 + t * 0.6);
  const b = Math.cos(y * 2.4 - t * 0.8 + seed * 0.5) + Math.cos(x * 3.1 + t * 1.1 + seed * 2.3) * 0.6 + Math.cos((x - y) * 1.9 - t * 0.7);
  return [a / 2.6, b / 2.6];
};

// Coptic letters typed with Latin keys in the Avva Shenouda font.
export const COPTIC = 'abgdezqiklmnxoprctufy'.split('');
