// Small timing / easing helpers for the logo intro. Everything works in
// seconds (t = frame / fps) so it lines up with cues.json.
import cuesJson from './cues.json';
import layoutJson from './layout.json';

export const cues = cuesJson;
export type Tile = {
  c: number;
  r: number;
  cov: number;
  avg: number[];
  land: number;
  step: number;
  rowK: number;
  flip: number;
  group: 'nono' | 'fofo' | null;
};
export const layout = layoutJson as unknown as {size: number; grid: number; tiles: Tile[]};

// Logo coordinates are the PNG's 512 px space.
export const LOGO_PX = layout.size;

export const clamp = (x: number, a = 0, b = 1) => Math.min(b, Math.max(a, x));
export const lerp = (a: number, b: number, p: number) => a + (b - a) * p;
export const prog = (t: number, a: number, b: number) => clamp((t - a) / (b - a));

export const ease = {
  outCubic: (p: number) => 1 - (1 - p) ** 3,
  inCubic: (p: number) => p ** 3,
  inOutCubic: (p: number) => (p < 0.5 ? 4 * p ** 3 : 1 - (-2 * p + 2) ** 3 / 2),
  outExpo: (p: number) => (p >= 1 ? 1 : 1 - 2 ** (-10 * p)),
  inExpo: (p: number) => (p <= 0 ? 0 : 2 ** (10 * p - 10)),
  inOutQuad: (p: number) => (p < 0.5 ? 2 * p * p : 1 - (-2 * p + 2) ** 2 / 2),
  outBack: (p: number, s = 1.7) => 1 + (s + 1) * (p - 1) ** 3 + s * (p - 1) ** 2,
  inOutBack: (p: number, s = 1.7 * 1.525) =>
    p < 0.5 ? ((2 * p) ** 2 * ((s + 1) * 2 * p - s)) / 2 : ((2 * p - 2) ** 2 * ((s + 1) * (p * 2 - 2) + s) + 2) / 2,
};

// Damped spring from 0 to 1 that starts at t0 (overshoots, then settles).
export const springAt = (t: number, t0: number, freq = 2.2, damp = 5.5) => {
  const x = t - t0;
  if (x <= 0) return 0;
  return 1 - Math.exp(-damp * x) * Math.cos(2 * Math.PI * freq * x);
};

// 0 -> 1 -> 0 decaying kick (flashes, shakes) that starts at t0.
export const kick = (t: number, t0: number, decay = 0.25) => {
  const x = t - t0;
  return x < 0 ? 0 : Math.exp(-x / (decay / 3));
};

// Deterministic pseudo random in [0, 1).
export const rnd = (seed: number) => {
  const s = Math.sin(seed * 12.9898 + 78.233) * 43758.5453;
  return s - Math.floor(s);
};

// Coptic letters (typed with Latin keys in the Avva Shenouda font).
export const COPTIC = 'abgdezqiklmnxoprctufy'.split('');

// Point along a polyline at p in [0, 1].
export const along = (pts: [number, number][], p: number): [number, number] => {
  const seg = pts.slice(1).map((b, i) => Math.hypot(b[0] - pts[i][0], b[1] - pts[i][1]));
  const total = seg.reduce((a, b) => a + b, 0);
  let d = clamp(p) * total;
  for (let i = 0; i < seg.length; i++) {
    if (d <= seg[i] || i === seg.length - 1) {
      const q = seg[i] ? d / seg[i] : 0;
      return [lerp(pts[i][0], pts[i + 1][0], q), lerp(pts[i][1], pts[i + 1][1], q)];
    }
    d -= seg[i];
  }
  return pts[pts.length - 1];
};
